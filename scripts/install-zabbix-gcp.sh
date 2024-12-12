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

#dnf -y install bind-utils
#dnf -y install gcc pcre-devel make libtool autoconf automake dbus-devel
#dnf -y install mariadb-server 
#dnf -y install mariadb-devel 
#dnf -y install mariadb-connector-odbc
#dnf -y install mariadb-connector-c-devel.x86_64
#dnf -y install postgresql-odbc
#dnf -y install libiodbc
#dnf -y install systemd-devel
#dnf -y install python3-systemd
#dnf -y install net-snmp net-snmp-libs net-snmp-utils
#rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
#dnf clean all
#dnf -y install ipmitool
#dnf -y install zabbix-server-mysql 
#dnf -y install zabbix-web-mysql 
#dnf -y install zabbix-apache-conf
#dnf -y install zabbix-sql-scripts 
#dnf -y install zabbix-selinux-policy 
#dnf -y install zabbix-agent 
#dnf -y install zabbix-agent2 
#dnf -y install zabbix-sender 
#dnf -y install zabbix-get
#dnf -y install zabbix-js
#dnf -y install perl-App-cpanminus
#dnf -y install perl-JSON.noarch
#dnf -y install ansible-core pip
#dnf -y install golang-github-prometheus-node-exporter
#pip3.9 install zabbix-api
#dnf -y update

cd /root/ && git clone https://github.com/smejdil/zabbix-edu
ansible-galaxy collection install community.zabbix --force
ansible-galaxy role install geerlingguy.mysql
ansible-galaxy role install geerlingguy.apache
ansible-galaxy role install geerlingguy.php

export ZABBIX_USER=Admin
export ZABBIX_PASSWORD=zabbix
export ZBX_PROBE_PASS
ansible-playbook /root/zabbix-edu/zabbix/ansible/install-zabbix-server-mysql.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-host-group-training.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-user-zbx_probe.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-template-training.yml

# EOF