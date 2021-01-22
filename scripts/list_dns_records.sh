#!/bin/sh
#
# List DNS record for zbx0x, linsrv01, winsrv01 and pfsense01
#
# Lukas Maly <Iam@LukasMaly.NET> 22.1.2021
#
clear

# zbx
for i in 01 02 03 04 05 06 07 08 09;
do
	echo "List DNS record zbx${i}.pfsense.cz:"
        cli4 /zones/:pfsense.cz/dns_records/:zbx${i}.pfsense.cz | jq '{"id":.id,"name":.name,"type":.type,"content":.content}'
done

# linsrv, winsrv, pfsense
for i in linsrv winsrv pfsense;
do
	echo "List DNS record ${i}01.pfsense.cz:"
        cli4 /zones/:pfsense.cz/dns_records/:${i}01.pfsense.cz | jq '{"id":.id,"name":.name,"type":.type,"content":.content}'
done

# EOF