## Deploy zabbix servers on GCP

This small project is used for install EDU servers with Zabbix 5.0 LTS on CentOS 8.

## Dependencies

- Package on desktop - google-cloud-sdk - Google Cloud SDK for Google Cloud Platform
- Package on desktop - py37-cloudflare - Wrapper for the Cloudflare v4 API

## How it works

By Google Cloud SDK is intalled servers zbx01-0X. After instalation run scripts for reconfigure OS and install Zabbix for education.

## Features

- Install and configure MariaDB
- Install and configure zabbix_server
- Install and configure zabbix_agentd with mysql modul
- Install and configure zabbix_agent2
- Install and configure Apache httpd and PHP7
- Install and configure ODBC driver for MariaDB
- Install and configure Zabbix API scripts Perl and CPAN modul
- Install and configure crontab file
- Install and configure Windows server 2019
- Install and configure Tomcat, PostgreSQL, Memcached, Docker ...

### Installation

- Configure Google Cloud SDK

```console
gcloud config set compute/zone [ZONE]
gcloud config set compute/region [REGION]
gcloud config set project [PROJECT]
```
## Zabbix servers
- Create VM Zabbix EDU

```console
./zabbix-edu/scripts/create_zabbix_vm_machines.sh 01 02 03
```
- Connect to VM Zabbix EDU and run scripts + reboot SELinux disable

```console
gcloud compute ssh zbx01
sudo su -
./zabbix-edu/scripts/reconfigure_sshd.sh
rebbot
./zabbix-edu/scripts/install_zabbix.sh
```
- List Zabbix EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5"/zabbix/"}' | grep zbx0
zbx01 - http://35.246.211.200/zabbix/
zbx02 - http://34.89.152.77/zabbix/
zbx03 - http://34.107.115.225/zabbix/
```
## Linux server for EDU
- Create VM Linux + Tomcat other

```console
./zabbix-edu/scripts/create_tomcat_vm_machine.sh 01
```
- Connect to VM Linux + Tomcat and run scripts + reboot SELinux disable

```console
gcloud compute ssh linsrv01
sudo su -
./zabbix-edu/scripts/reconfigure_sshd.sh
rebbot
./zabbix-edu/scripts/install_configure_app.sh
```
## Windows server for EDU
- Create VM Windows server 2019

```console
./zabbix-edu/scripts/create_windows_vm_machine.sh 01
```
## DNS A records for EDU
- Create DNS records

```console
cli4 --post name='zbx01' type=A content="35.246.211.200" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx02' type=A content="34.89.152.77" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx03' type=A content="34.107.115.225" /zones/:pfsense.cz/dns_records

cli4 --post name='winsrv01' type=A content="34.107.108.40" /zones/:pfsense.cz/dns_records
cli4 --post name='linsrv01' type=A content="34.107.28.86" /zones/:pfsense.cz/dns_records
```
## To do

- Create Zabbix user by Zabbix API
- Import training Tmplate by Zabbix API
- Import media Email by Zabbix API
- Download and Install Zabbix Agent 2 on winsrv01 by PowerShell
- Install - Web Server and IIS Management Scripts and Tools on winsrv01 by PowerShell
- Other ...