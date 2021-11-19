#!/bin/bash
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 13.10.2021
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
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf -y install ipmitool
dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent zabbix-agent2 zabbix-sender zabbix-get zabbix-java-gateway
dnf -y install perl-App-cpanminus
dnf -y install perl-JSON.noarch
dnf -y install ansible
dnf -y install golang-github-prometheus-node-exporter
pip3 install zabbix-api
dnf -y update
cd /root/ && git clone https://github.com/smejdil/zabbix-edu
ansible-galaxy collection install -r /root/zabbix-edu/zabbix/requirements.yml
#cpanm JSON::RPC::Client > /tmp/cpan.log
#! Finding JSON::RPC::Client on cpanmetadb failed.
#! Finding JSON::RPC::Client () on mirror http://www.cpan.org failed.
#! Couldn't find module or a distribution JSON::RPC::Client

# EOF