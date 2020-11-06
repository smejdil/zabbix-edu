#!/bin/sh
#
# Install package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 5.11.2020
#

dnf -y install git
dnf -y install bash-completion
dnf -y install epel-release
dnf -y install joe vim mc wget
dnf -y install gcc pcre-devel mariadb-devel make
dnf -y install libtool autoconf automake dbus-devel
dnf -y install systemd-devel
dnf -y install python3-systemd
dnf -y install mariadb-connector-odbc
dnf -y install postgresql-odbc
dnf -y install libiodbc
dnf -y install net-snmp net-snmp-libs net-snmp-utils
dnf -y install perl-App-cpanminus

dnf -y update

# Install CPAN Perl modul
./zabbix-edu/zabbix/api/install_cpan_modul.sh

# EOF
