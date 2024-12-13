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
apt install -y policycoreutils

# Configure SSH
echo "--- SSHD ---"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

#sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

diff -u /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

#systemctl restart sshd.service
systemctl restart ssh.service

openssl rand -base64 32 > /root/root-user.pw
ROOT_PASS=`cat /root/root-user.pw`

openssl rand -base64 32 > /root/zbx-user.pw
ZBX_PASS=`cat /root/zbx-user.pw`

echo "--- ROOT ---"
#echo ${ROOT_PASS} | passwd root --stdin
echo "root:${ROOT_PASS}" | chpasswd

echo "--- ZABBIX ---"
useradd -G adm,google-sudoers -p zabbix zbx
#echo ${ZBX_PASS} | passwd zbx --stdin
echo "root:${ZBX_PASS}" | chpasswd

# disable SELinux
echo "--- SELinux ---"
cp /etc/selinux/config /etc/selinux/config-orig
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

diff -u /etc/selinux/config-orig /etc/selinux/config

#echo "--- Reboot ---"
#reboot

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