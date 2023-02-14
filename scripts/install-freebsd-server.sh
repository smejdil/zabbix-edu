#!/bin/sh
#
# Install FreeBSD packages
#
# Lukas Maly <Iam@LukasMaly.NET> 14.2.2023
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

#cd /usr/ports/lang/lua54 && make install clean
#cd /usr/ports/converters/lua-json && make install clean
#cd /usr/ports/net/luasocket && make install clean

# EOF