#!/bin/bash
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 22.5.2023
#

# Post deploy commands
dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo-orig
sed -i 's/# place its address here./excludepkgs=zabbix*/g' /etc/yum.repos.d/epel.repo
dnf -y install joe vim mc wget
dnf -y install bind-utils
dnf -y install gcc pcre-devel make libtool autoconf automake dbus-devel
dnf -y install mariadb-server 
#dnf -y install mariadb-devel 
dnf -y install mariadb-connector-odbc
dnf -y install mariadb-connector-c-devel.x86_64
dnf -y install postgresql-odbc
dnf -y install libiodbc
dnf -y install systemd-devel
dnf -y install python3-systemd
dnf -y install net-snmp net-snmp-libs net-snmp-utils
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm
dnf clean all
dnf -y install ipmitool
dnf -y install zabbix-server-mysql 
dnf -y install zabbix-web-mysql 
dnf -y install zabbix-apache-conf
dnf -y install zabbix-sql-scripts 
dnf -y install zabbix-selinux-policy 
dnf -y install zabbix-agent 
dnf -y install zabbix-agent2 
dnf -y install zabbix-sender 
dnf -y install zabbix-get
dnf -y install zabbix-js
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