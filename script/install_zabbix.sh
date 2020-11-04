#!/bin/bash
#
# Zabbix install scpript
#

### MariaDB

dnf -y install mariadb-server

systemctl enable mariadb.service
systemctl start mariadb.service

openssl rand -base64 32 > /root/mysql-root.pw
MYSQL_ROOT_PASS=`cat /root/mysql-root.pw`

mysqladmin -u root password '${MYSQL_ROOT_PASS}'

openssl rand -base64 32 > /root/mysql-zabbix.pw
ZABBIX_MYSQL_PASS=`cat /root/mysql-zabbix.pw`

#mysql -u root -p
#create database zabbix character set utf8 collate utf8_bin;
#grant all privileges on zabbix.* to zabbix@localhost identified by '${ZABBIX_MYSQL_PASS}';
#FLUSH PRIVILEGES;
#quit;

### Zabbix
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
dnf clean all
dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent 

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -p${ZABBIX_MYSQL_PASS}

# Zabbix configuration
cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf-orig
sed -i "s/^# DBPassword=/DBPassword=${ZABBIX_MYSQL_PASS}/g" /etc/zabbix/zabbix_server.conf
diff -u /etc/zabbix/zabbix_server.conf-orig /etc/zabbix/zabbix_server.conf

cp /etc/php-fpm.d/zabbix.conf /etc/php-fpm.d/zabbix.conf-orig 
sed -i "s/^; php_value\[date.timezone\] = Europe\/Riga/php_value\[date.timezone\] = Europe\/Prague/g" /etc/php-fpm.d/zabbix.conf
diff -u /etc/php-fpm.d/zabbix.conf-orig /etc/php-fpm.d/zabbix.conf

systemctl restart zabbix-server zabbix-agent httpd php-fpm
systemctl enable zabbix-server zabbix-agent httpd php-fpm 

# http://server_ip_or_name/zabbix

# EOF
