#!/usr/bin/env python3
"""Configure the training environment using the Zabbix 7.0 JSON-RPC API.

Only the Python standard library is required. Safe to rerun after a failed setup.
"""
import json
import os
from pathlib import Path
import secrets
import string
import sys
import time
from urllib.error import URLError
from urllib.request import Request, urlopen


class ZabbixAPI:
    def __init__(self, url):
        self.url = url
        self.token = None
        self.request_id = 0

    def call(self, method, params):
        self.request_id += 1
        payload = {"jsonrpc": "2.0", "method": method, "params": params,
                   "id": self.request_id}
        headers = {"Content-Type": "application/json-rpc"}
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        request = Request(self.url, json.dumps(payload).encode(), headers)
        with urlopen(request, timeout=30) as response:
            result = json.load(response)
        if "error" in result:
            error = result["error"]
            raise RuntimeError(f"{method}: {error.get('message')}: {error.get('data')}")
        return result["result"]


def stored_password(path, forbidden=()):
    if path.exists():
        password = path.read_text().strip()
        if not password:
            raise RuntimeError(f"Password file {path} is empty")
        if all(part.casefold() not in password.casefold() for part in forbidden):
            return password
    # Include every character class used by the default Zabbix password policy.
    alphabet = string.ascii_letters + string.digits + "!@#%_+-="
    while True:
        password = "".join(secrets.choice(chars) for chars in (
            string.ascii_uppercase, string.ascii_lowercase, string.digits, "!@#%_+-="
        )) + "".join(secrets.choice(alphabet) for _ in range(28))
        if all(part.casefold() not in password.casefold() for part in forbidden):
            break
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Replace a previously generated password rejected by Zabbix atomically.
    temporary = path.with_name(path.name + "." + secrets.token_hex(8) + ".tmp")
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w") as stream:
        stream.write(password + "\n")
    os.replace(temporary, path)
    return password


def login_admin(api):
    path = Path(os.environ.get("ZABBIX_ADMIN_PASSWORD_FILE", "/root/zabbix-admin.pw"))
    desired = stored_password(path)
    username = os.environ.get("ZABBIX_USER", "Admin")
    candidates = list(dict.fromkeys((desired, os.environ.get("ZABBIX_PASSWORD", "zabbix"), "zabbix")))
    for current in candidates:
        try:
            api.token = api.call("user.login", {"username": username, "password": current})
            break
        except RuntimeError:
            pass
    else:
        raise RuntimeError("Admin login failed with saved and supplied passwords")

    if current != desired:
        users = api.call("user.get", {"output": ["userid"], "filter": {"username": username}})
        if len(users) != 1:
            raise RuntimeError("Cannot identify Admin account for password update")
        result = api.call("user.update", {
            "userid": users[0]["userid"], "current_passwd": current, "passwd": desired,
        })
        if users[0]["userid"] not in result.get("userids", []):
            raise RuntimeError("Admin password update was not confirmed by API")
        api.token = None  # Changing own password invalidates the previous session.
        api.token = api.call("user.login", {"username": username, "password": desired})
    print(f"Admin password is stored in {path} (root only).")


def main(rotate_only=False):
    api = ZabbixAPI(os.environ.get("ZABBIX_API_URL", "http://127.0.0.1/zabbix/api_jsonrpc.php"))
    for attempt in range(60):
        try:
            version = api.call("apiinfo.version", {})
            break
        except (URLError, ValueError, RuntimeError):
            if attempt == 59:
                raise RuntimeError("Zabbix API did not become ready within 5 minutes")
            time.sleep(5)
    if not version.startswith("7.0."):
        raise RuntimeError(f"Expected Zabbix 7.0, got {version}")
    login_admin(api)
    try:
        if rotate_only:
            return
        if not api.call("hostgroup.get", {"filter": {"name": "Training"}}):
            api.call("hostgroup.create", {"name": "Training"})
        api.call("settings.update", {"default_timezone": "Europe/Prague"})
        groups = api.call("usergroup.get", {"filter": {"name": "Zabbix administrators"}})
        roles = api.call("role.get", {"filter": {"name": "Super admin role"}})
        if not groups or not roles:
            raise RuntimeError("Default administrator group or role is missing")
        users = api.call("user.get", {"filter": {"username": "zbx_probe"}})
        probe_password = stored_password(
            Path(os.environ.get("ZBX_PROBE_PASSWORD_FILE", "/root/zbx-probe.pw")),
            forbidden=("zbx_probe", "zabbix", "probe"),
        )
        user = {
            "name": "Zabbix", "surname": "Probe",
            "passwd": probe_password,
            "roleid": roles[0]["roleid"],
            "usrgrps": [{"usrgrpid": groups[0]["usrgrpid"]}],
            "lang": "en_US", "timezone": "Europe/Prague",
            "theme": "blue-theme", "autologin": 0, "autologout": "0",
            "refresh": "30s", "rows_per_page": 200,
        }
        if users:
            user["userid"] = users[0]["userid"]
            api.call("user.update", user)
        else:
            user["username"] = "zbx_probe"
            api.call("user.create", user)
        source = Path(os.environ.get("ZABBIX_TEMPLATE_PATH") or (
            Path(__file__).resolve().parents[1] / "zabbix/templates/Templates-Training-Zabbix-7.0.xml"
        ))
        rules = {name: {"createMissing": True, "updateExisting": True} for name in (
            "template_groups", "templates", "items", "discoveryRules", "triggers",
            "graphs", "valueMaps", "httptests",
        )}
        rules["templateLinkage"] = {"createMissing": True}
        if api.call("configuration.import", {
            "format": "xml", "source": source.read_text(), "rules": rules,
        }) is not True:
            raise RuntimeError("Training template import did not succeed")
        print(f"Zabbix {version}: Training group, probe user, timezone and templates configured.")
    finally:
        api.call("user.logout", [])


if __name__ == "__main__":
    try:
        main(rotate_only="--rotate-admin-only" in sys.argv[1:])
    except Exception as error:
        print(f"Training configuration failed: {error}", file=sys.stderr)
        sys.exit(1)
