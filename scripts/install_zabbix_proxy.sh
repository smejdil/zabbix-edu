#!/bin/bash
#
# Zabbix proxy install scpript
#
# Lukas Maly <Iam@LukasMaly.NET> 10.11.2021
#

# Install rpm package zabbix-proxy
dnf -y install zabbix-proxy-mysql.x86_64

echo "--- Zabbix proxy DB user ---"
openssl rand -base64 32 > /root/mysql-zabbix-proxy.pw
ZABBIX_PROXY_MYSQL_PASS=`cat /root/mysql-zabbix-proxy.pw`

MYSQL_ROOT_PASS=`cat /root/mysql-root.pw`

# Create database and user
mysql -u root -p${MYSQL_ROOT_PASS} -e "create database zabbix_proxy character set utf8 collate utf8_bin;"
mysql -u root -p${MYSQL_ROOT_PASS} -e "grant all privileges on zabbix_proxy.* to zabbix_proxy@localhost identified by '${ZABBIX_PROXY_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

### Zabbix proxy

# Import db schema
echo "--- Import DB schema ---"
zcat /usr/share/doc/zabbix-proxy-mysql/schema.sql.gz | mysql -u zabbix_proxy -p${ZABBIX_PROXY_MYSQL_PASS} zabbix_proxy

# Zabbix configuration
echo "--- Configure Zabbix proxy config ---"
cp -v /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf-orig
sed -i "s/^# ListenPort=10051/# ListenPort=10053/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/Hostname=Zabbix proxy/Hostname=zbxp-local/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^DBName=zabbix_proxy/DBHost=zabbix_proxy/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^DBUser=zabbix/DBUser=zabbix_proxy/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s|^# DBPassword=|DBPassword=${ZABBIX_PROXY_MYSQL_PASS}|g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# Timeout=3/Timeout=30/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# CacheSize=8M/CacheSize=32M/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBSocket=/DBSocket=\/var\/lib\/mysql\/mysql.sock/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# StartVMwareCollectors=0/StartVMwareCollectors=1/g" /etc/zabbix/zabbix_proxy.conf
diff -u /etc/zabbix/zabbix_proxy.conf-orig /etc/zabbix//etc/zabbix/zabbix_proxy.conf

# Restart services
echo "--- Restart and enable services ---"
systemctl restart zabbix-proxy
systemctl enable zabbix-proxy

### EOF
