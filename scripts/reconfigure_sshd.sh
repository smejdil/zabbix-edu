#!/bin/sh
#
# Script change system post deploy configuration
#
# Lukas Maly <Iam@LukasMaly.NET> 6.11.2020
#

cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

diff -u /etc/ssh/sshd_config /etc/ssh/sshd_config-orig

systemctl restart sshd.service

echo zabbix | passwd root --stdin

# disable SELinux
cp /etc/selinux/config /etc/selinux/config-orig
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

diff -u /etc/selinux/config-orig /etc/selinux/config

# Install CPAN Perl modul
#./zabbix-edu/zabbix/api/install_cpan_modul.sh

reboot

# EOF
