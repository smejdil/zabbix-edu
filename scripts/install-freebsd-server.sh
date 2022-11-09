#!/bin/sh
#
# Install FreeBSD packages
#
# Lukas Maly <Iam@LukasMaly.NET> 9.11.2022
#

pkg -y install joe mc git

echo "BATCH=yes" > /etc/make.conf

portsnap fetch && portsnap extract

cd /usr/ports/devel/py-pip && make install clean
cd /usr/ports/sysutils/ansible && make install clean
pip install zabbix-api

# Zabbix Agent !!!

cd /root
git clone https://github.com/smejdil/zabbix-ansible

# EOF