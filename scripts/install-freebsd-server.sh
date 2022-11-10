#!/bin/sh
#
# Install FreeBSD packages
#
# Lukas Maly <Iam@LukasMaly.NET> 9.11.2022
#

pkg install -y joe mc git

echo "BATCH=yes" > /etc/make.conf

portsnap fetch
portsnap extract

cd /usr/ports/devel/p5-JSON-RPC && make install clean
cd /usr/ports/devel/py-pip && make install clean
cd /usr/ports/sysutils/ansible && make install clean

pip install zabbix-api

pkg install -y zabbix6-agent
/usr/local/etc/rc.d/zabbix_agentd enable
# sed edit config

cd /root
git clone https://github.com/smejdil/zabbix-api

# EOF