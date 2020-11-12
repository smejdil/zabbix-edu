#!/bin/bash
#
# Tomcat install scpript and Other SW
#
# Lukas Maly <Iam@LukasMaly.NET> 12.11.2020
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
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf
diff -u /etc/zabbix/zabbix_agent2.conf-orig /etc/zabbix/zabbix_agent2.conf

systemctl restart zabbix-agent2

## System user for SSH check
echo "--- System user for SSH ---"

adduser --shell /bin/bash --home /home/zbx_probe zbx_probe
echo ${ZBX_PROBE_PASS} | passwd zbx_probe --stdin

# System user zbx_probe and the zabbix user have the same password. cat /root/zbx_probe.pw

### Tomcat

# mod_jk for Apache

mkdir /tmp/install && cd /tmp/install
wget http://mirror.dkm.cz/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.48-src.tar.gz

tar xvzf tomcat-connectors-1.2.48-src.tar.gz
cd tomcat-connectors-1.2.48-src/native

which apxs

./configure --with-apxs=/usr/bin/apxs
make

libtool --finish /usr/lib64/httpd/modules
make install

cd
cp -v ./zabbix-edu/files/00-jk.conf /etc/httpd/conf.modules.d/
cp -v ./zabbix-edu/files/workers.properties /etc/httpd/conf/
cp -v ./zabbix-edu/files/mod_jk.conf /etc/httpd/conf.d/

systemctl restart httpd

# Tomcat

systemctl enable tomcat.service
systemctl restart tomcat.service

# JMX enable

cd /etc/tomcat
#joe tomcat.conf
#CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=10059 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

systemctl restart tomcat

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

# EOF
