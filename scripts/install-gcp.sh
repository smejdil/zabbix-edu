#!/bin/bash
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 27.1.2023
#

# Post deploy commands
dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
dnf -y install joe vim mc wget
dnf -y install bind-utils
dnf -y install gcc pcre-devel make libtool autoconf automake dbus-devel
dnf -y install mariadb-server mariadb-devel mariadb-connector-odbc
dnf -y install postgresql-odbc
dnf -y install libiodbc
dnf -y install systemd-devel
dnf -y install python3-systemd
dnf -y install net-snmp net-snmp-libs net-snmp-utils
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
dnf clean all
dnf -y install ipmitool
dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent zabbix-agent2 zabbix-sender zabbix-get zabbix-java-gateway zabbix-js
dnf -y install perl-App-cpanminus
dnf -y install perl-JSON.noarch
dnf -y install ansible-core pip
dnf -y install golang-github-prometheus-node-exporter
pip3.9 install zabbix-api
dnf -y update
cd /root/ && git clone https://github.com/smejdil/zabbix-edu
ansible-galaxy collection install community.zabbix
#ansible-galaxy collection install --force -r /root/zabbix-edu/zabbix/requirements.yml

#cpanm JSON::RPC::Client > /tmp/cpan.log
#! Finding JSON::RPC::Client on cpanmetadb failed.
#! Finding JSON::RPC::Client () on mirror http://www.cpan.org failed.
#! Couldn't find module or a distribution JSON::RPC::Client

# EOF