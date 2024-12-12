#!/bin/bash
#
# Install package
#
# Lukas Maly <Iam@LukasMaly.NET> 12.12.2024
#

# Post deploy commands
apt update
apt install -y git
apt install -y bash-completion
apt install -y joe vim mc wget
apt install -y ansible
apt install -y ipmitool
apt install -y aptitude
apt install -y odbc-mariadb
apt install -y snmp
apt install -y python3-pip
apt install -y prometheus-node-exporter

# Get repo
cd /root/ && git clone https://github.com/smejdil/zabbix-edu
ansible-galaxy collection install community.zabbix --force
ansible-galaxy role install geerlingguy.mysql
ansible-galaxy role install geerlingguy.apache
ansible-galaxy role install geerlingguy.php

export ZABBIX_USER=Admin
export ZABBIX_PASSWORD=zabbix
export ZBX_PROBE_PASS

# Install Zabbix server
sudo ansible-playbook /root/zabbix-edu/zabbix/ansible/install-zabbix-server-mysql.yml > /tmp/install-zabbix-server-mysql.yml.log
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-host-group-training.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-user-zbx_probe.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-template-training.yml

echo "Done" > /root/Done

# EOF