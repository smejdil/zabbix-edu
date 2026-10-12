#!/bin/sh
# Install the FreeBSD training tools and Zabbix agent from binary packages.
set -eu

pkg update
pkg install -y bash joe mc git screen jq zabbix7-agent

agent_conf=/usr/local/etc/zabbix7/zabbix_agentd.conf
if [ ! -f "$agent_conf" ]; then
    echo "Zabbix agent configuration not found: $agent_conf" >&2
    exit 1
fi
if [ ! -f "${agent_conf}-orig" ]; then
    cp "$agent_conf" "${agent_conf}-orig"
fi
sed -i '' -e 's|^Server=.*|Server=127.0.0.1,enceladus.pfsense.cz|' "$agent_conf"
sysrc zabbix_agentd_enable=YES

echo 'Zabbix agent configured; FreeBSD will start it during boot.'
