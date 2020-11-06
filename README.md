## Deploy zabbix servers on GCP

This small project is used for install EDU servers with Zabbix 5.0 LTS on CentOS 8.

## Dependencies

- Package on dektop - google-cloud-sdk - Google Cloud SDK for Google Cloud Platform
- Package on dektop - py37-cloudflare - Wrapper for the Cloudflare v4 API

## How it works

By Google Cloud SDK is intaled servers zbxXX. After instalation run scripts for reconfigure OS and install Zabbix for education.

## Features

- Install and configure MariaDB
- Install and configure zabbix_server
- Install and configure zabbix_agentd with mysql modul
- Install and configure zabbix_agent2
- Install and configure Apache httpd and PHP7
- Install and configure ODBC driver for MariaDB
- Install and configure Zabbix API scripts Perl and CPAN modul
- Install and configure crontab file

### Installation

- Configure Google Cloud SDK

```
gcloud config set compute/zone [ZONE]
gcloud config set compute/region [REGION]
gcloud config set project [PROJECT]
```

- Create VM

```
cd /home/malyl/work/zabbix-edu
./scripts/create_zabbix_vm_machines.sh 01 02 03
```
- Connect to VM and run scripts

```
gcloud compute ssh zbx01
sudo su -
git clone https://github.com/smejdil/zabbix-edu
./zabbix-edu/scripts/reconfigure_sshd.sh
```
- Connect to VM and run scripts

```
gcloud compute ssh zbx01
sudo su -
./zabbix-edu/scripts/install_zabbix.sh
```
- List VM and external IPv4

```
gcloud compute instances list | awk '{print $1" - "$5}' | grep zbx
zbx01 - 35.246.211.200
zbx02 - 34.89.152.77
zbx03 - 34.107.115.225
```
- Create DNS records

```
cli4 --post name='zbx01' type=A content="35.246.211.200" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx02' type=A content="34.89.152.77" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx03' type=A content="34.107.115.225" /zones/:pfsense.cz/dns_records
```
## To do

- Create Zabbix user by Zabbix API
- Import training Tmplate by Zabbix API
- Import media by Zabbix API
- Other ...