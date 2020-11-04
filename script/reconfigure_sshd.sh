#!/bin/sh

cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

diff -u /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

systemctl restart sshd.service

echo zabbix | passwd root --stdin

# EOF
