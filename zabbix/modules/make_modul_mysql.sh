#!/bin/sh
#
# Easy build shell script for Zabbix agent
#
# Lukas Maly <Iam@LukasMaly.NET> 6.11.2020
#
ZBX_VERSION=`rpm -qa | grep 'zabbix-agent-' | awk 'BEGIN{FS="-"}{print $3}'`
ZBX_MAJOR_VERSION=`rpm -qa | grep 'zabbix-agent-' | awk 'BEGIN{FS="-"}{print $3}' | awk 'BEGIN{FS="."}{print $1}'`
ZBX_MAJOR2_VERSION=`rpm -qa | grep 'zabbix-agent-' | awk 'BEGIN{FS="-"}{print $3}' | awk 'BEGIN{FS="."}{print $2}'`

rm -rf zabbix-${ZBX_VERSION}
rm -rf zabbix-*.tar.gz

# git clone https://github.com/cnshawncao/zabbix-module-mysql (private)
wget https://cdn.zabbix.com/zabbix/sources/stable/${ZBX_MAJOR_VERSION}.${ZBX_MAJOR2_VERSION}/zabbix-${ZBX_VERSION}.tar.gz

tar xvzf zabbix-${ZBX_VERSION}.tar.gz

cp -r module-mysql zabbix-${ZBX_VERSION}/src/modules/mysql
cd zabbix-${ZBX_VERSION}

./configure --enable-agent
cd src/modules/mysql
make

cp mysql.so /usr/lib/zabbix/modules

echo "--- Installed Zabbix modules ---"
ls -1 /usr/lib/zabbix/modules

# EOF
