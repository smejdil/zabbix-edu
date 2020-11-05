#!/bin/bash
#
# Zabbix install scpript
#
# Lukas Maly <Iam@LukasMaly.NET> 5.11.2020
#

### MariaDB
dnf -y install mariadb-server

systemctl enable mariadb.service
systemctl start mariadb.service

openssl rand -base64 32 > /root/mysql-root.pw
MYSQL_ROOT_PASS=`cat /root/mysql-root.pw`

# Set up root password
mysqladmin -u root password ${MYSQL_ROOT_PASS};

openssl rand -base64 32 > /root/mysql-zabbix.pw
ZABBIX_MYSQL_PASS=`cat /root/mysql-zabbix.pw`

# Create database and user
mysql -u root -p${MYSQL_ROOT_PASS} -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -u root -p${MYSQL_ROOT_PASS} -e "grant all privileges on zabbix.* to zabbix@localhost identified by '${ZABBIX_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

### Zabbix
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent zabbix-agent2 zabbix-sender zabbix-get

# Import db schema
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p${ZABBIX_MYSQL_PASS} zabbix

# Zabbix configuration
cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf-orig
sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_server.conf
sed -i "s|^# DBPassword=|DBPassword=${ZABBIX_MYSQL_PASS}|g" /etc/zabbix/zabbix_server.conf
sed -i "s/# Timeout=3/Timeout=30/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# CacheSize=8M/CacheSize=32M/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# DBSocket=/DBSocket=\/var\/lib\/mysql\/mysql.sock/g" /etc/zabbix/zabbix_server.conf
diff -u /etc/zabbix/zabbix_server.conf-orig /etc/zabbix/zabbix_server.conf

cp /etc/php-fpm.d/zabbix.conf /etc/php-fpm.d/zabbix.conf-orig 
sed -i 's/^; php_value\[date.timezone\] = Europe\/Riga/php_value\[date.timezone\] = Europe\/Prague/g' /etc/php-fpm.d/zabbix.conf
diff -u /etc/php-fpm.d/zabbix.conf-orig /etc/php-fpm.d/zabbix.conf

# Restart services 
systemctl restart zabbix-server zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-agent2 httpd php-fpm

# Copy frontend config file
cp ./zabbix-edu/script/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
chmod 400 /etc/zabbix/web/zabbix.conf.php
chown apache:apache /etc/zabbix/web/zabbix.conf.php

sed -i "s|XXX|${ZABBIX_MYSQL_PASS}|g" /etc/zabbix/web/zabbix.conf.php
sed -i "s|YYY|EDU Zabbix|g" /etc/zabbix/web/zabbix.conf.php

# Make agent modules

mkdir -p /usr/lib/zabbix/modules

# ODBC

openssl rand -base64 32 > /root/mysql-zbx_probe.pw
ZBX_PROBE_MYSQL_PASS=`cat /root/mysql-zbx_probe.pw`

mysql -u root -p${MYSQL_ROOT_PASS} -e "GRANT select ON *.* TO 'zbx_probe'@'127.0.0.1' IDENTIFIED BY '${ZBX_PROBE_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

cp ./zabbix-edu/zabbix/odbc.ini /etc/odbc.ini
odbcinst -j

# crontab
cp ./zabbix-edu/crontab/zabbix-training /etc/cron.d/

# Zabbix agent a agent2
cp ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agentd.d/
cp ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agent2.d/

# http://server_ip_or_name/zabbix

# EOF
