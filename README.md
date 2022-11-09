## Deploy zabbix servers on GCP

This small project is used for install EDU servers with Zabbix 5.0 LTS on CentOS Stream release 8.

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
- Install and configure Ansible collection zabbix
- Install and configure crontab file
- Install and configure Windows server 2019
- Install and configure Tomcat, PostgreSQL, Memcached, Docker ...
- Install and configure FreeBSD server

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
gcloud compute ssh zbx01 --zone=europe-west1-c
sudo su -
./zabbix-edu/scripts/reconfigure_sshd.sh
reboot
./zabbix-edu/scripts/install_zabbix.sh
```
- List Zabbix EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5"/zabbix/"}' | grep zbx0
zbx01 - http://35.246.211.200/zabbix/
zbx02 - http://34.89.152.77/zabbix/
zbx03 - http://34.107.115.225/zabbix/

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz/zabbix/"}' | grep zbx0
34.89.152.77 - http://zbx01.pfsense.cz/zabbix/
35.198.167.115 - http://zbx02.pfsense.cz/zabbix/
34.107.115.225 - http://zbx03.pfsense.cz/zabbix/
```
## Linux server for EDU
- Create VM Linux + Tomcat other

```console
./zabbix-edu/scripts/create_tomcat_vm_machine.sh 01
```
- Connect to VM Linux + Tomcat and run scripts + reboot SELinux disable

```console
gcloud compute ssh linsrv01 --zone=europe-central2-a
sudo su -
./zabbix-edu/scripts/reconfigure_sshd.sh
reboot
./zabbix-edu/scripts/install_configure_app.sh
```
- List Linux servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep linsrv0
linsrv01 - http://34.107.114.128

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep linsrv0
34.107.114.128 - http://linsrv01.pfsense.cz
```

## FreeBSD server for EDU
- Create VM FreeBSD

```console
./zabbix-edu/scripts/create_fbsd_vm_machine.sh 01
```

- Connect to VM FreeBSD

```console
gcloud compute ssh fbsdsv01 --zone=europe-central2-a
```
- List FreeBSD servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep fbsdsrv0
fbsdsrv01 - http://34.107.114.182

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep fbsdsrv0
34.107.114.182 - http://fbsdsrv01.pfsense.cz
```

## Windows server for EDU
- Create VM Windows server 2019

```console
./zabbix-edu/scripts/create_windows_vm_machine.sh 01
```
- List Windows servers EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep winsrv0
winsrv01 - http://34.89.189.246

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep winsrv0
34.89.189.246 - http://winsrv01.pfsense.cz
```
Manual configure Win server and install IIS and Zabbix agent 2.

```console
less ./zabbix-edu/docs/Windows-on-GCP.txt
```

## pfSense CE on GCP for EDU
- Create VM firewall pfSense

Manual deploy on GCP web console.

```console
less ./zabbix-edu/docs/pfSense-CE-on-GCP.txt
```

- List pfSense firewall EDU VM and external IPv4

```console
gcloud compute instances list | awk '{print $1" - http://"$5}' | grep pfsense
pfsense-edu - http://34.90.171.187

gcloud compute instances list | awk '{print $5" - http://"$1".pfsense.cz"}' | grep pfsense
34.90.171.187 - http://pfsense-edu.pfsense.cz
```

## DNS A records for EDU
- Create DNS records via cloudflare API

```console
./zabbix-edu/scripts/create_dns_records.sh

cli4 --post name='zbx01' type=A content="35.246.211.200" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx02' type=A content="34.89.152.77" /zones/:pfsense.cz/dns_records
cli4 --post name='zbx03' type=A content="34.107.115.225" /zones/:pfsense.cz/dns_records
cli4 --post name='winsrv01' type=A content="34.107.108.40" /zones/:pfsense.cz/dns_records
cli4 --post name='linsrv01' type=A content="34.107.28.86" /zones/:pfsense.cz/dns_records
cli4 --post name='pfsense01' type=A content="34.90.171.187" /zones/:pfsense.cz/dns_records
```

List of Zabbix server domain and IPv4

```console
for i in {01..12}; do host zbx$i.pfsense.cz; done
zbx01.pfsense.cz has address 35.246.211.200
zbx02.pfsense.cz has address 34.89.152.77
zbx03.pfsense.cz has address 34.107.115.225
```

## HTML list of VM
- Create HTML list of running EDU VM

```console
./zabbix-edu/scripts/create_html_list.sh
```
## Other training projects

- [Zabbix API](https://github.com/smejdil/zabbix-api)
- [Zabbix auto-registration](https://github.com/smejdil/zbx-auto-reg-demo-gcp)
- [Zabbix Docker TimescaleDB](https://github.com/smejdil/zabbix-docker-timescaledb)

## To do

- Import media Email by Zabbix API - Anslible
- Download and Install Zabbix Agent 2 on winsrv01 by PowerShell
- Install - Web Server and IIS Management Scripts and Tools on winsrv01 by PowerShell
- Other ...