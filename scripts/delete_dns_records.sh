#!/bin/sh
#
# Delete DNS record for zbx0x, linsrv01, winsrv01, fbsdsrv01 and pfsense01
#
# Lukas Maly <Iam@LukasMaly.NET> 9.11.2022
#
clear

# zbx
for i in 01 02 03 04 05 06 07 08 09;
do
	echo "Delete DNS record zbx${i}.pfsense.cz:"
        cli4 /zones/:pfsense.cz/dns_records/:zbx${i}.pfsense.cz | jq '{"id":.id,"name":.name,"type":.type,"content":.content}'
        cli4 --delete /zones/:pfsense.cz/dns_records/:zbx${i}.pfsense.cz | jq -c .
done

# linsrv, winsrv, fbsdsrv,
for i in linsrv winsrv fbsdsrv;
do
	echo "Delete DNS record ${i}01.pfsense.cz:"
        cli4 /zones/:pfsense.cz/dns_records/:${i}01.pfsense.cz | jq '{"id":.id,"name":.name,"type":.type,"content":.content}'
        cli4 --delete /zones/:pfsense.cz/dns_records/:${i}01.pfsense.cz | jq -c .
done

cli4 /zones/:pfsense.cz/dns_records/:pfsense-edu.pfsense.cz | jq '{"id":.id,"name":.name,"type":.type,"content":.content}'
cli4 --delete /zones/:pfsense.cz/dns_records/:pfsense-edu.pfsense.cz | jq -c .

# EOF
