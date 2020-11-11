#!/bin/bash
#
# Tomcat install scpript and Other SW
#
# Lukas Maly <Iam@LukasMaly.NET> 11.11.2020
#

### Zabbix

# Restart services
echo "--- Restart and enable services ---"
systemctl enable zabbix-agent2 httpd

## Zabbix agent and agent2
echo "--- Zabbix Agent's ---"

cp -v /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf-orig
sed -i 's/# LoadModulePath=${libdir}\/modules/LoadModulePath=\/usr\/lib\/zabbix\/modules/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/#Hostname=Zabbix server/g' /etc/zabbix/zabbix_agentd.conf
diff -u /etc/zabbix/zabbix_agentd.conf-orig /etc/zabbix/zabbix_agentd.conf

systemctl restart zabbix-agent2

## System user for SSH check
echo "--- System user for SSH ---"

adduser --shell /bin/bash --home /home/zbx_probe zbx_probe
echo ${ZBX_PROBE_PASS} | passwd zbx_probe --stdin

# System user zbx_probe and the zabbix user have the same password. cat /root/zbx_probe.pw

# Tomcat

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

cd /etc/httpd
#joe conf.modules.d/00-jk.conf
#LoadModule jk_module modules/mod_jk.so

#joe /etc/httpd/conf/workers.properties
#worker.list=worker1
#worker.worker1.type=ajp13
#worker.worker1.port=8009
#worker.worker1.host=localhost
#worker.worker1.lbfactor=1

#joe conf.d/mod_jk.conf

#JkWorkersFile /etc/httpd/conf/workers.properties
#JkLogFile     /var/log/httpd/mod_jk_log
#JkLogLevel    info
#JkMount       /* worker1

systemctl restart httpd

# Tomcat

systemctl enable tomcat.service
systemctl start tomcat.service

# JMX enable

cd /etc/tomcat
#joe tomcat.conf
#CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=10059 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

systemctl restart tomcat

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
