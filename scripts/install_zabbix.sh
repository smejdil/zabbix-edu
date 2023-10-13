#!/bin/bash
#
# Zabbix install scpript
#
# Lukas Maly <Iam@LukasMaly.NET> 10.10.2023
#

### MariaDB
echo "--- MariaDB ---"

systemctl enable mariadb.service
systemctl start mariadb.service

openssl rand -base64 32 > /root/mysql-root.pw
MYSQL_ROOT_PASS=`cat /root/mysql-root.pw`

# Set up root password
echo "--- MaiaDB root pw ---"
mysqladmin -u root password ${MYSQL_ROOT_PASS};
 
echo "--- Zabbix DB user ---"
openssl rand -base64 32 > /root/mysql-zabbix.pw
ZABBIX_MYSQL_PASS=`cat /root/mysql-zabbix.pw`

# Create database and user
mysql -u root -p${MYSQL_ROOT_PASS} -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -u root -p${MYSQL_ROOT_PASS} -e "create user zabbix@localhost identified by '${ZABBIX_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "grant all privileges on zabbix.* to zabbix@localhost;"
mysql -u root -p${MYSQL_ROOT_PASS} -e "set global log_bin_trust_function_creators = 1;"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

### Zabbix

# Import db schema
echo "--- Import DB schema ---"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p${ZABBIX_MYSQL_PASS} zabbix

# Disable log_bin_trust_function_creators option after importing database schema. 
mysql -u root -p${MYSQL_ROOT_PASS} -e "set global log_bin_trust_function_creators = 0;"

# Zabbix configuration
echo "--- Configure Zabbix server config ---"
cp -v /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf-orig
sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_server.conf
sed -i "s|^# DBPassword=|DBPassword=${ZABBIX_MYSQL_PASS}|g" /etc/zabbix/zabbix_server.conf
sed -i "s/# Timeout=3/Timeout=30/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# CacheSize=8M/CacheSize=32M/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# DBSocket=/DBSocket=\/var\/lib\/mysql\/mysql.sock/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# StartVMwareCollectors=0/StartVMwareCollectors=1/g" /etc/zabbix/zabbix_server.conf
diff -u /etc/zabbix/zabbix_server.conf-orig /etc/zabbix/zabbix_server.conf

## Zabbix Java Gateway
sed -i "s/# JavaGateway=/JavaGateway=127.0.0.1/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# JavaGatewayPort=10052/JavaGatewayPort=10052/g" /etc/zabbix/zabbix_server.conf
sed -i "s/# StartJavaPollers=0/StartJavaPollers=1/g" /etc/zabbix/zabbix_server.conf

echo "--- Configure PHP config ---"
cp -v /etc/php-fpm.d/zabbix.conf /etc/php-fpm.d/zabbix.conf-orig 
sed -i 's/^; php_value\[date.timezone\] = Europe\/Riga/php_value\[date.timezone\] = Europe\/Prague/g' /etc/php-fpm.d/zabbix.conf
diff -u /etc/php-fpm.d/zabbix.conf-orig /etc/php-fpm.d/zabbix.conf

# Restart services
echo "--- Restart and enable services ---"
cp -v ./zabbix-edu/files/server-status.conf /etc/httpd/conf.d/
systemctl restart zabbix-server zabbix-java-gateway zabbix-agent2 httpd php-fpm
systemctl enable zabbix-server zabbix-java-gateway zabbix-agent2 httpd php-fpm

# Copy frontend config file
echo "--- Zabbix frontend config ---"
cp -v ./zabbix-edu/scripts/zabbix.conf.php /etc/zabbix/web/zabbix.conf.php
chmod 400 /etc/zabbix/web/zabbix.conf.php
chown apache:apache /etc/zabbix/web/zabbix.conf.php

sed -i "s|XXX|${ZABBIX_MYSQL_PASS}|g" /etc/zabbix/web/zabbix.conf.php
sed -i "s|YYY|EDU Zabbix|g" /etc/zabbix/web/zabbix.conf.php

# http://server_ip_or_name/zabbix

# ODBC
echo "--- ODBC ---"
openssl rand -base64 32 > /root/mysql-zbx_probe.pw
ZBX_PROBE_MYSQL_PASS=`cat /root/mysql-zbx_probe.pw`

mysql -u root -p${MYSQL_ROOT_PASS} -e "GRANT select ON *.* TO zbx_probe@localhost IDENTIFIED BY '${ZBX_PROBE_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

cp -v ./zabbix-edu/zabbix/odbc.ini /etc/odbc.ini
odbcinst -j

# Test DB Size
# isql -v zabbix zbx_probe ${ZBX_PROBE_MYSQL_PASS}
# select SUM(data_length) from information_schema.tables where table_schema = 'zabbix'

## crontab
echo "--- Cron ---"
cp -v ./zabbix-edu/crontab/zabbix-training /etc/cron.d/

## Zabbix external script's
cp -v ./zabbix-edu/zabbix/externalscripts/*.sh /usr/lib/zabbix/externalscripts/
chmod 700 /usr/lib/zabbix/externalscripts/*.sh
chown zabbix:zabbix /usr/lib/zabbix/externalscripts/*.sh

## Zabbix agent a agent2
echo "--- Zabbix Agent's ---"
cp -v ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agentd.d/
cp -v ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agent2.d/

# Get MariaDB sources
#MARIADB_VER=`rpm -qa | grep mariadb-10 | awk 'BEGIN {FS="-"}{print $2}' | cut -d. -f1,2`
#git clone -b ${MARIADB_VER} https://github.com/MariaDB/server.git

# Make agent modules
#echo "--- Zabbix Agent's modules ---"
#mkdir -p /usr/lib/zabbix/modules

#cp -R /root/server/include/* /usr/local/include/

#cd ./zabbix-edu/zabbix/modules
#./make_modul_mysql.sh # :-( mysql_version.h ...

# Zabbix agentd
cp -v /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf-orig
sed -i 's/# LoadModulePath=${libdir}\/modules/LoadModulePath=\/usr\/lib\/zabbix\/modules/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Server=127.0.0.1/Server=127.0.0.1,enceladus.pfsense.cz/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/# LogRemoteCommands=0/LogRemoteCommands=1/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/# DenyKey=system.run\[\*\]/AllowKey=system.run\[\*\]/g' /etc/zabbix/zabbix_agentd.conf
diff -u /etc/zabbix/zabbix_agentd.conf-orig /etc/zabbix/zabbix_agentd.conf

cd
cp -v ./zabbix-edu/zabbix/zabbix_agentd.d/libzbxmysql.conf /etc/zabbix/zabbix_agentd.d/libzbxmysql.conf
cp -v ./zabbix-edu/zabbix/modules/module-mysql/zbx_module_mysql.conf /etc/zabbix/

# Zabbix agent2
cp -v /etc/zabbix/zabbix_agent2.conf /etc/zabbix/zabbix_agent2.conf-orig
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/Server=127.0.0.1/Server=127.0.0.1,enceladus.pfsense.cz/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/# LogRemoteCommands=0/LogRemoteCommands=1/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/# DenyKey=system.run\[\*\]/AllowKey=system.run\[\*\]/g' /etc/zabbix/zabbix_agent2.conf
diff -u /etc/zabbix/zabbix_agent2.conf-orig /etc/zabbix/zabbix_agent2.conf

echo "--- Monitoring DB user ---"
openssl rand -base64 32 > /root/mysql-monitoring.pw
MONITORING_MYSQL_PASS=`cat /root/mysql-monitoring.pw`

# Create user for modul

mysql -u root -p${MYSQL_ROOT_PASS} -e "GRANT PROCESS, SUPER ON *.* TO monitoring@localhost IDENTIFIED BY '${MONITORING_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'monitoring'@'%' IDENTIFIED BY '${MONITORING_MYSQL_PASS}';"
mysql -u root -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"

sed -i 's/^mysql_inst_ports =/mysql_inst_ports = 3306/g' /etc/zabbix/zbx_module_mysql.conf
sed -i 's/^mysql_inst_user =/mysql_inst_user = monitoring/g' /etc/zabbix/zbx_module_mysql.conf
sed -i "s|^mysql_inst_password =|mysql_inst_password = ${MONITORING_MYSQL_PASS}|g" /etc/zabbix/zbx_module_mysql.conf

# Manual change agent2 to agentd
# systemctl stop zabbix-agent2.service
# systemctl start zabbix-agent.service

# Test modulu
#zabbix_get -s 127.0.0.1 -I 127.0.0.1 -k mysql.discovery
#{"data":[{"{#MYSQLHOST}":"127.0.0.1","{#MYSQLPORT}":"3306"}]}

systemctl stop zabbix-agent
systemctl disable zabbix-agent
systemctl restart zabbix-agent2.service

### API user nad Perl example
echo "--- API ---"
openssl rand -base64 32 > /root/zbx_probe.pw
ZBX_PROBE_PASS=`cat /root/zbx_probe.pw`

# Create Zabbix user with this password ${ZBX_PROBE_PASS}

cd ./zabbix-edu/zabbix/api/
./install.sh

sed -i "s|^password => \"ZBXlab\"|password => \"${ZBX_PROBE_PASS}\"|g" /usr/share/zabbix/auth.pl
sed -i "s|^password => \"ZBXlab\"|password => \"${ZBX_PROBE_PASS}\"|g" /usr/share/zabbix/hosts.pl

# http://server_ip_or_name/zabbix/perl_auth.php
# http://server_ip_or_name/zabbix/perl_hosts.php

## System user for SSH check
echo "--- System user for SSH ---"

adduser --shell /bin/bash --home /home/zbx_probe zbx_probe
echo ${ZBX_PROBE_PASS} | passwd zbx_probe --stdin

# System user zbx_probe and the zabbix user have the same password. cat /root/zbx_probe.pw

# Ansile Zabbix
export ZABBIX_USER=Admin
export ZABBIX_PASSWORD=zabbix
export ZBX_PROBE_PASS
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-host-group-training.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-user-zbx_probe.yml
ansible-playbook /root/zabbix-edu/zabbix/ansible/add-template-training.yml

# Prometeus - Node exporter

# curl localhost:9100/metrics | grep -v '#'
# http://zbx01.pfsense.cz:9100/metrics

systemctl enable prometheus-node-exporter.service
systemctl start prometheus-node-exporter.service

### EOF
