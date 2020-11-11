#!/bin/sh
#
# Install Tomcat package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 11.11.2020
#

dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
dnf -y install joe vim mc wget
dnf -y install tomcat
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
dnf clean all
dnf -y install zabbix-agent zabbix-agent2 zabbix-sender zabbix-get
dnf -y update
cd /root/ && git clone https://github.com/smejdil/zabbix-edu

# EOF
