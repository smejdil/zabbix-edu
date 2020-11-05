# Deploy zabbix servers on GCP

This small project is used for install EDU servers with Zaabix 5 on CentOS-8.

# Dependencies

- Package on dektop - google-cloud-sdk		Google Cloud SDK for Google Cloud Platform
- Package on dektop - py37-cloudflare			Wrapper for the Cloudflare v4 API

# How it works

By google cloud api is intaled servers zbxXX. After instalation run script for reconfigure OS and install Zabbix.

### Installation

- Create VM

```
cd /home/malyl/work/zabbix-edu
./script/create_zabbix_vm_machines.sh 01 02 03
```
- Connect to VM and run scripts

```
gcloud compute ssh zbx01
sudo su -
yum -y install git
git clone https://github.com/smejdil/zabbix-edu
./zabbix-edu/script/reconfigure_sshd.sh
```
- Connect to VM and run scripts

```
gcloud compute ssh zbx01
sudo su -
./zabbix-edu/script/install_zabbix.sh
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
# To do

...