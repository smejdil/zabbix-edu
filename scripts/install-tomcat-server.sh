#!/bin/sh
#
# Install Tomcat package and extra repo
#
# Lukas Maly <Iam@LukasMaly.NET> 11.11.2020
#

yum -y install git
yum -y install bash-completion
yum -y install epel-release
yum -y install joe vim mc wget
dnf -y install bind-utils
yum -y install httpd
yum -y install tomcat tomcat-native tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp
yum -y install yum-utils device-mapper-persistent-data 
yum -y install httpd-devel apr apr-devel apr-util apr-util-devel gcc make libtool autoconf libtool-ltdl-devel
yum -y install ipmitool
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all
yum -y install zabbix-agent zabbix-agent2 zabbix-sender zabbix-get
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
yum -y update
cd /root/
git clone https://github.com/smejdil/zabbix-edu
git clone https://github.com/zabbix/zabbix-docker
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# EOF
