#!/bin/bash
dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
dnf -y install joe vim mc wget
dnf -y install gcc pcre-devel
dnf -y install mariadb-devel
dnf -y install make libtool autoconf automake dbus-devel
dnf -y install systemd-devel
dnf -y install python3-systemd
dnf -y install mariadb-connector-odbc
dnf -y install postgresql-odbc
dnf -y install libiodbc
dnf -y install net-snmp net-snmp-libs net-snmp-utils
dnf -y install perl-App-cpanminus
dnf -y update
cd /root/ && git clone https://github.com/smejdil/zabbix-edu
cpanm JSON::RPC::Client > /tmp/cpan.log