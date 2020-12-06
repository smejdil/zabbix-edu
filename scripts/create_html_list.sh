#!/bin/sh
#
# Create HTML file
#
# Lukas Maly <Iam@LukasMaly.NET> 4.12.2020
#

# ./zabbix-edu/scripts/create_html_list.sh

GCP_CMD_LIST="gcloud compute instances list"

echo "<html><body>" > ./zabbix-edu/files/vm_url_ipv4.html
echo "<ul >" >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/zabbix/\">http://"$1".pfsense.cz/zabbix/</a> - "$5"<br>"}' | grep zbx0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep linsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep winsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep pfsense0 >> ./zabbix-edu/files/vm_url_ipv4.html
echo "<ul>" >> ./zabbix-edu/files/vm_url_ipv4.html
echo "</body></html>" >> ./zabbix-edu/files/vm_url_ipv4.html

# EOF
