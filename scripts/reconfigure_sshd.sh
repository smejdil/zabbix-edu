#!/bin/sh
#
# Script change system post deploy configuration
#
# Lukas Maly <Iam@LukasMaly.NET> 15.1.2021
#
echo "--- SSHD ---"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

#sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

diff -u /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

systemctl restart sshd.service

openssl rand -base64 32 > /root/root-user.pw
ROOT_PASS=`cat /root/root-user.pw`

openssl rand -base64 32 > /root/zbx-user.pw
ZBX_PASS=`cat /root/zbx-user.pw`

echo "--- ROOT ---"
echo ${ROOT_PASS} | passwd root --stdin

echo "--- ZABBIX ---"
useradd -G adm,google-sudoers -p zabbix zbx
echo ${ZBX_PASS} | passwd zbx --stdin

# disable SELinux
echo "--- SELinux ---"
cp /etc/selinux/config /etc/selinux/config-orig
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

diff -u /etc/selinux/config-orig /etc/selinux/config

echo "--- Reboot ---"
reboot

# EOF
