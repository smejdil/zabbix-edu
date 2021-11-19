#!/bin/bash

VAULT_RETRIES=5
echo "Vault is starting..."
until vault status > /dev/null 2>&1 || [ "$VAULT_RETRIES" -eq 0 ]; do
	echo "Waiting for vault to start...: $((VAULT_RETRIES--))"
	sleep 1
done

echo "Authenticating to vault..."
vault login token=DataScript-ZabbixEDU202X

echo "Initializing vault..."
vault secrets enable -version=2 -path=zabbix kv

echo "Adding entries..."
vault kv put zabbix ZBX_PROBE_MYSQL_PASS=ASce6qQA9gtyWiGnGpmj
vault kv put zabbix SSH_USER_PASS=8VsnE5QiYexIu4kazcBI
vault kv put zabbix ZBX_PROBE_VMWARE_PASS=8VsnE5QiYexIu4kazcBI

echo "Complete..."
