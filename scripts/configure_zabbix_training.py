#!/usr/bin/env python3
"""Configure the training environment using the Zabbix 7.0 JSON-RPC API.

Only the Python standard library is required. Safe to rerun after a failed setup.
"""
import json
import os
from pathlib import Path
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


def main():
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
    api.token = api.call("user.login", {
        "username": os.environ.get("ZABBIX_USER", "Admin"),
        "password": os.environ.get("ZABBIX_PASSWORD", "zabbix"),
    })
    try:
        if not api.call("hostgroup.get", {"filter": {"name": "Training"}}):
            api.call("hostgroup.create", {"name": "Training"})
        api.call("settings.update", {"default_timezone": "Europe/Prague"})
        groups = api.call("usergroup.get", {"filter": {"name": "Zabbix administrators"}})
        roles = api.call("role.get", {"filter": {"name": "Super admin role"}})
        if not groups or not roles:
            raise RuntimeError("Default administrator group or role is missing")
        users = api.call("user.get", {"filter": {"username": "zbx_probe"}})
        user = {
            "name": "Zabbix", "surname": "Probe",
            "passwd": os.environ.get("ZBX_PROBE_PASS", "ZabbixEDU_Probe_Pass"),
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
        source = Path(__file__).resolve().parents[1] / "zabbix/templates/Templates-Training-Zabbix-7.0.xml"
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
        main()
    except Exception as error:
        print(f"Training configuration failed: {error}", file=sys.stderr)
        sys.exit(1)
