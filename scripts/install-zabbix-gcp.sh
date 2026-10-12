#!/usr/bin/env bash
# First-boot bootstrap; install locally without Galaxy roles or collections.
set -Eeuo pipefail
umask 077
exec > >(tee -a /var/log/zabbix-edu-install.log) 2>&1
trap 'echo "Installation failed at line $LINENO. See /var/log/zabbix-edu-install.log" >&2' ERR
exec 9>/var/lock/zabbix-edu-install.lock
flock -n 9 || exit 0
[[ ! -f /root/Done ]] || { echo 'Training installation already completed.'; exit 0; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git ansible ca-certificates curl openssl
REPO=/root/zabbix-edu
if [[ ! -d "$REPO/.git" ]]; then
    git clone https://github.com/smejdil/zabbix-edu "$REPO"
fi
# Preserve generated passwords when resuming an interrupted installation.
for account in root zbx; do
    password_file="/root/${account}-user.pw"
    [[ -s "$password_file" ]] || openssl rand -base64 32 > "$password_file"
    if [[ $account == zbx ]] && ! id zbx >/dev/null 2>&1; then
        useradd -m -s /bin/bash -G adm,google-sudoers zbx
    fi
    printf '%s:%s\n' "$account" "$(cat "$password_file")" | chpasswd
done
export ZABBIX_USER=${ZABBIX_USER:-Admin}
export ZABBIX_PASSWORD=${ZABBIX_PASSWORD:-zabbix}
export ZBX_PROBE_PASS=${ZBX_PROBE_PASS:-ZabbixEDU_Probe_Pass}
ansible-playbook -i localhost, -c local "$REPO/zabbix/ansible/install-zabbix-server-mysql.yml"
python3 "$REPO/scripts/configure_zabbix_training.py"
for service in mysql apache2 zabbix-server zabbix-agent2 zabbix-java-gateway; do
    systemctl is-active --quiet "$service"
done
curl --fail --silent --show-error http://127.0.0.1/zabbix/ >/dev/null
agent_ready=false
for attempt in {1..30}; do
    if [[ $(zabbix_get -s 127.0.0.1 -k agent.ping 2>/dev/null) == 1 ]]; then
        agent_ready=true
        break
    fi
    sleep 2
done
[[ $agent_ready == true ]] || { echo 'Agent 2 did not become ready' >&2; exit 1; }
printf 'Done %s\n' "$(date -Is)" > /root/Done
echo 'Training installation completed. Frontend: http://VM_IP/zabbix/'
