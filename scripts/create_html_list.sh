#!/bin/sh
#
# Create HTML file
#
# Lukas Maly <Iam@LukasMaly.NET> 15.1.2021
#

# ./zabbix-edu/scripts/create_html_list.sh

# GCP Set project Zabbix-EDU
gcloud config set project zabbix-edu

GCP_CMD_LIST="gcloud compute instances list"

# Generate html list of IPv4
echo "<html><body>" > ./zabbix-edu/files/vm_url_ipv4.html
echo "<ul >" >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/zabbix/\">http://"$1".pfsense.cz/zabbix/</a> - "$5"<br>"}' | grep zbx0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep linsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep winsrv0 >> ./zabbix-edu/files/vm_url_ipv4.html
${GCP_CMD_LIST} | awk '{print "<li><a href=\"http://"$1".pfsense.cz/\">http://"$1".pfsense.cz/</a> - "$5"<br>"}' | grep pfsense0 >> ./zabbix-edu/files/vm_url_ipv4.html
echo "<ul>" >> ./zabbix-edu/files/vm_url_ipv4.html
echo "</body></html>" >> ./zabbix-edu/files/vm_url_ipv4.html

# Generate only zbx0 list of IPv4 for mod_status on linsrv01
${GCP_CMD_LIST} | grep ^zbx0 | awk '{print $5}' > ./zabbix-edu/files/zbx_vm_ipv4.txt

# EOF
