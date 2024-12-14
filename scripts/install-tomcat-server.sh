#!/bin/sh
#
# Install Tomcat package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 14.12.2024
#

yum -y install git
yum -y install bash-completion
yum -y install epel-release
yum -y install joe vim mc wget
yum -y install bind-utils
yum -y install openssl
yum -y install httpd
yum -y install tomcat.noarch tomcat-native tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp mod_jk
yum -y install patch
yum -y install yum-utils device-mapper-persistent-data 
yum -y install httpd-devel apr apr-devel apr-util apr-util-devel gcc make libtool autoconf libtool-ltdl-devel
yum -y install ipmitool
yum -y install net-snmp net-snmp-utils
yum -y install golang-github-prometheus-node-exporter
#rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-5.el9.noarch.rpm
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/centos/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
yum clean all
yum -y install zabbix-agent2 zabbix-sender zabbix-get
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
yum -y update
cd /root/
git clone https://github.com/smejdil/zabbix-edu
git clone https://github.com/zabbix/zabbix-docker
curl -L https://github.com/docker/compose/releases/download/v2.7.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose 
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# EOF