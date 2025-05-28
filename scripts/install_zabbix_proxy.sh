#!/bin/bash
#
# Zabbix proxy install scpript
#
# Lukas Maly <Iam@LukasMaly.NET> 26.05.2025
#

# Install deb package zabbix-proxy
apt -y install zabbix-proxy-mysql

echo "--- Zabbix proxy DB user ---"
openssl rand -base64 32 > /root/mysql-zabbix-proxy.pw
ZABBIX_PROXY_MYSQL_PASS=`cat /root/mysql-zabbix-proxy.pw`

MYSQL_ROOT_PASS=`cat /root/mysql-root.pw`

# Create database and user
#mysql -u root -p${MYSQL_ROOT_PASS} -e "create database zabbix_proxy character set utf8 collate utf8_bin;"
#mysql -u root -p${MYSQL_ROOT_PASS} -e "grant all privileges on zabbix_proxy.* to zabbix_proxy@localhost identified by '${ZABBIX_PROXY_MYSQL_PASS}';"
#mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

mysql -u root -e "create database zabbix_proxy character set utf8 collate utf8_bin;"
mysql -u root -e "CREATE USER 'zabbix_proxy'@'localhost' IDENTIFIED BY '${ZABBIX_PROXY_MYSQL_PASS}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON zabbix_proxy.* TO 'zabbix_proxy'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

### Zabbix proxy

# Import db schema
echo "--- Import DB schema ---"
cat /usr/share/zabbix-sql-scripts/mysql/proxy.sql | mysql -u zabbix_proxy -p${ZABBIX_PROXY_MYSQL_PASS} zabbix_proxy

# Zabbix configuration
echo "--- Configure Zabbix proxy config ---"
cp -v /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf-orig
sed -i "s/^# ListenPort=10051/ListenPort=10054/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/Hostname=Zabbix proxy/Hostname=zbxp-local/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_proxy.conf
#sed -i "s/^DBName=zabbix_proxy/DBName=zabbix_proxy/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/^DBUser=zabbix/DBUser=zabbix_proxy/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s|^# DBPassword=|DBPassword=${ZABBIX_PROXY_MYSQL_PASS}|g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# Timeout=3/Timeout=30/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# CacheSize=8M/CacheSize=32M/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# DBSocket=/DBSocket=\/var\/lib\/mysql\/mysql.sock/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/# StartVMwareCollectors=0/StartVMwareCollectors=1/g" /etc/zabbix/zabbix_proxy.conf
sed -i "s/DBSocket=\/var\/lib\/mysql\/mysql.sock/DBSocket=\/var\/run\/mysqld\/mysqld.sock/g" /etc/zabbix/zabbix_proxy.conf

diff -u /etc/zabbix/zabbix_proxy.conf-orig /etc/zabbix/zabbix_proxy.conf

# Restart services
echo "--- Restart and enable services ---"
systemctl enable zabbix-proxy.service
systemctl restart zabbix-proxy.service

### EOF
