#!/bin/sh
#
# Create DNS record for Zabbix EDU
#
# Lukas Maly <Iam@LukasMaly.NET> 12.11.2020
#

EXCLUDE=`cat exclude-hosts.txt`

clear
for i in `gcloud compute instances list | grep -v NAME | awk '{print $1";"$5}'| egrep -v "${EXCLUDE}"`;
do 
	NAME=`echo $i | awk 'BEGIN {FS=";"}{print $1}'`;
	IPV4=`echo $i | awk 'BEGIN {FS=";"}{print $2}'`;
	echo "Create DNS A record in domain pfsense.cz:"
	echo "-----------------------------------------------------------------------------------------------"
	echo "cli4 --post name='${NAME}' type=A content=\"${IPV4}\" /zones/:pfsense.cz/dns_records"
	echo "-----------------------------------------------------------------------------------------------"
	/usr/local/bin/cli4 --post name='${NAME}' type=A content="${IPV4}" /zones/:pfsense.cz/dns_records
done