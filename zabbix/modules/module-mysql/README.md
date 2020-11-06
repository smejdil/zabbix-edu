Description
===========

This directory contains a sample module, which extends functionality of Zabbix Agent. 

Status
======

This module is testing.

Installation
============

```bash

	$ git clone https://github.com/cnshawncao/zabbix-module-mysql.git
	$ cp -r zabbix-module-mysql zabbix-x.x.x/src/modules/mysql	# zabbix-x.x.x is zabbix version
```

1. run 'make' to build it. It should produce mysql.so.

1. copy mysql.so to the module directory, like LoadModulePath=/etc/zabbix/modules

1. change config file add line : LoadModule=mysql.so

1. cp zbx_module_mysql.conf to /etc/zabbix, modify it

	mysql_inst_ports = 3306,192.168.9.9:3307,3308:S

	mysql_inst_user = USER
	
	mysql_inst_password = PASSWORD

1. restart zabbix_agent daemon

1. import the mysql and mysql slave template

1. create mysql user

	GRANT PROCESS, SUPER ON *.* TO 'USER'@'127.0.0.1' IDENTIFIED BY 'PASSWORD';

1. link the template to the host

Synopsis
========

**key:** *mysql.discovery*

**value:**

	{"data":[{"{#MYSQLHOST}":"127.0.0.1","{#MYSQLPORT}":"3306"},{"{#MYSQLHOST}":"192.168.9.9","{#MYSQLPORT}":"3307"},{"{#MYSQLHOST}":"127.0.0.1","{#MYSQLPORT}":"3308"}]}
    
**key:** *mysql.status[{#MYSQLHOST},{#MYSQLPORT},key]*

**key:** *mysql.ping[{#MYSQLHOST},{#MYSQLPORT}]*

**key:** *mysql.slave.discovery*

**value:**

	{"data":[{"{#MYSQLSLAVEHOST}":"127.0.0.1","{#MYSQLSLAVEPORT}":"3308"}]}

**key:** *mysql.slave.status[{#MYSQLSLAVEHOST},{#MYSQLSLAVEPORT},key]*
