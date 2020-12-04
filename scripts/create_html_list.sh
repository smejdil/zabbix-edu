#!/bin/sh
#
# Create HTML file
#
# Lukas Maly <Iam@LukasMaly.NET> 4.12.2020
#

echo "<html><body>" > ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/zabbix/\">http://"$1".pfsense.cz/zabbix/</a>"}' | grep zbx0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a>"}' | grep linsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a>"}' | grep winsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a>"}' | grep pfsense0 >> ./zabbix-edu/files/vm_url_ipv4.html
echo "</body></html>" >> ./zabbix-edu/files/vm_url_ipv4.html