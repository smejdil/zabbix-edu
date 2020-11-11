# Add firewall rules for Zabbix Agent
netsh advfirewall firewall add rule name="Zabbix Agent" dir=in action=allow protocol=TCP localport=10050
netsh advfirewall firewall add rule name="Zabbix Agent" dir=out action=allow protocol=TCP localport=10050
netsh advfirewall firewall add rule name="Zabbix Agent" dir=in action=allow protocol=UDP localport=10050
netsh advfirewall firewall add rule name="Zabbix Agent" dir=out action=allow protocol=UDP localport=10050