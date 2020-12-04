#!/bin/sh
#
# Create HTML file
#
# Lukas Maly <Iam@LukasMaly.NET> 4.12.2020
#

# ./zabbix-edu/scripts/create_html_list.sh

echo "<html><body>" > ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/zabbix/\">http://"$1".pfsense.cz/zabbix/</a><br>"}' | grep zbx0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a><br>"}' | grep linsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a><br>"}' | grep winsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
gcloud compute instances list | awk '{print $5" - <a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a><br>"}' | grep pfsense0 >> ./zabbix-edu/files/vm_url_ipv4.html
echo "</body></html>" >> ./zabbix-edu/files/vm_url_ipv4.html