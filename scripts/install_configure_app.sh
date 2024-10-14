#!/bin/bash
#
# Tomcat install scpript and Other SW
#
# Lukas Maly <Iam@LukasMaly.NET> 7.11.2022
#

### Firewall
systemctl stop iptables.service
systemctl disable iptables.service

### Zabbix

# Restart services
echo "--- Restart and enable services ---"
systemctl enable zabbix-agent2 httpd

## Zabbix agent and agent2
echo "--- Zabbix Agent's ---"

cp -v /etc/zabbix/zabbix_agent2.conf /etc/zabbix/zabbix_agent2.conf-orig
cp -v ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agent2.d/
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/Server=127.0.0.1/Server=enceladus.pfsense.cz,zbx01.pfsense.cz,zbx02.pfsense.cz,zbx03.pfsense.cz,zbx04.pfsense.cz,zbx05.pfsense.cz,zbx06.pfsense.cz,zbx07.pfsense.cz,zbx08.pfsense.cz,zbx09.pfsense.cz,zbx10.pfsense.cz,zbx11.pfsense.cz,zbx12.pfsense.cz/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=enceladus.pfsense.cz,zbx01.pfsense.cz,zbx02.pfsense.cz,zbx03.pfsense.cz,zbx04.pfsense.cz,zbx05.pfsense.cz,zbx06.pfsense.cz,zbx07.pfsense.cz,zbx08.pfsense.cz,zbx09.pfsense.cz,zbx10.pfsense.cz,zbx11.pfsense.cz,zbx12.pfsense.cz/g' /etc/zabbix/zabbix_agent2.conf
sed -i 's/# Timeout=3/Timeout=30/g' /etc/zabbix/zabbix_agent2.conf
diff -u /etc/zabbix/zabbix_agent2.conf-orig /etc/zabbix/zabbix_agent2.conf

systemctl restart zabbix-agent2

#cp -v /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf-orig
#cp -v ./zabbix-edu/zabbix/zabbix_agentd.d/training.conf /etc/zabbix/zabbix_agentd.d/
#sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/Server=127.0.0.1/Server=enceladus.pfsense.cz,zbx01.pfsense.cz,zbx02.pfsense.cz,zbx03.pfsense.cz,zbx04.pfsense.cz,zbx05.pfsense.cz,zbx06.pfsense.cz,zbx07.pfsense.cz,zbx08.pfsense.cz,zbx09.pfsense.cz,zbx10.pfsense.cz,zbx11.pfsense.cz,zbx12.pfsense.cz/g' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/ServerActive=127.0.0.1/ServerActive=enceladus.pfsense.cz,zbx01.pfsense.cz,zbx02.pfsense.cz,zbx03.pfsense.cz,zbx04.pfsense.cz,zbx05.pfsense.cz,zbx06.pfsense.cz,zbx07.pfsense.cz,zbx08.pfsense.cz,zbx09.pfsense.cz,zbx10.pfsense.cz,zbx11.pfsense.cz,zbx12.pfsense.cz/g' /etc/zabbix/zabbix_agentd.conf
#sed -i 's/# Timeout=3/Timeout=30/g' /etc/zabbix/zabbix_agentd.conf
#diff -u /etc/zabbix/zabbix_agentd.conf-orig /etc/zabbix/zabbix_agentd.conf

# systemctl restart zabbix-agentd

## System user for SSH check
echo "--- System user for SSH ---"

adduser --shell /bin/bash --home /home/zbx_probe zbx_probe
echo ${ZBX_PROBE_PASS} | passwd zbx_probe --stdin

# System user zbx_probe and the zabbix user have the same password. cat /root/zbx_probe.pw

### Tomcat

# mod_jk for Apache

#mkdir /tmp/install && cd /tmp/install
#wget https://dlcdn.apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.49-src.tar.gz

#tar xvzf tomcat-connectors-1.2.49-src.tar.gz
#cd tomcat-connectors-1.2.49-src/native

#which apxs

#./configure --with-apxs=/usr/bin/apxs
#make

#libtool --finish /usr/lib64/httpd/modules
#make install

cd
cp -v ./zabbix-edu/files/00-jk.conf /etc/httpd/conf.modules.d/
cp -v ./zabbix-edu/files/workers.properties /etc/httpd/conf/
cp -v ./zabbix-edu/files/mod_jk.conf /etc/httpd/conf.d/
cp -v ./zabbix-edu/files/server-status.conf /etc/httpd/conf.d/

systemctl restart httpd

# Tomcat

systemctl enable tomcat.service

# JMX enable

cd /etc/tomcat
echo "CATALINA_OPTS=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=10059 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false\"" >> tomcat.conf

systemctl restart tomcat.service

# Manual test JMX
#grep -i jmx /var/log/tomcat/catalina.2020-11-11.log 
#INFO: Command line argument: -Dcom.sun.management.jmxremote
#INFO: Command line argument: -Dcom.sun.management.jmxremote.port=10059
#INFO: Command line argument: -Dcom.sun.management.jmxremote.ssl=false
#INFO: Command line argument: -Dcom.sun.management.jmxremote.authenticate=false

#netstat -anlp | grep 10059
#tcp6       0      0 :::10059                :::*                    LISTEN      15766/java

#Template-Training_App_Apache_Tomcat_JMX
#Template-Training_App_Generic_Java_JMX

# Docker
groupmems -a zabbix -g root
groupmems -a zabbix -g docker
systemctl enable docker.service
systemctl start docker.service

# Dockerized PostgreSQL
# https://hub.docker.com/_/postgres
docker run --name postgres -e POSTGRES_PASSWORD=123456 -d postgres
#docker run --name httpd -p 80:80 -d httpd

# Install Vault by HashiCorp
# http://linsrv01.pfsense.cz:8200 - Token RootAkademie-ZabbixEDU202X
cd /root/zabbix-edu/zabbix/docker-vault
#docker build -t vault .
docker-compose -f docker-compose.yml up -d

## Zabbix Docker
#cd /root/zabbix-docker
#docker-compose -f docker-compose_v3_centos_mysql_latest.yaml up -d

# Test Docker by Agnet 2
#zabbix_get -s linsrv01.pfsense.cz -p 10050 -k "docker.images.discovery"

# Emulace IPMI
#https://github.com/vapor-ware/ipmi-simulator

#docker pull vaporio/ipmi-simulator
#docker run -d -p 623:623/udp vaporio/ipmi-simulator

#docker run --name ipm-emulator -d -p 623:623/udp vaporio/ipmi-simulator

#ipmitool -H 10.45.2.15 -U ADMIN -P ADMIN -I lanplus chassis status
#ipmitool -H 127.0.0.1 -U ADMIN -P ADMIN -I lanplus chassis status
#System Power         : on
#Power Overload       : false
#Power Interlock      : inactive
#Main Power Fault     : false
#Power Control Fault  : false
#Power Restore Policy : always-off
#Last Power Event     :
#Chassis Intrusion    : inactive
#Front-Panel Lockout  : inactive
#Drive Fault          : false
#Cooling/Fan Fault    : false

# SNMPd
systemctl enable snmpd.service
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf-inst
systemctl restart snmpd.service

#snmpwalk -Os -c public -v 2c linsrv01.pfsense.cz system

# Prometeus - Node exporter

# curl localhost:9100/metrics | grep -v '#'
# http://linsrv01.pfsense.cz:9100/metrics

systemctl enable prometheus-node-exporter.service
systemctl start prometheus-node-exporter.service

# EOF
