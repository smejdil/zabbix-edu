#!/bin/sh
#
# Delete DNS record for starlink and create new
#
# Lukas Maly <Iam@LukasMaly.NET> 30.4.2022
#
clear

# starlink
echo "Delete DNS record starlink.pfsense.cz"
cli4 /zones/:pfsense.cz/dns_records/:starlink.pfsense.cz | jq -c '.[]|{"id":.id,"name":.name,"type":.type,"content":.content}'
cli4 --delete /zones/:pfsense.cz/dns_records/:starlink.pfsense.cz | jq -c .

echo "Create DNS A record in domain pfsense.cz:"
cli4 --post name='starlink' type=A content="145.224.105.240" /zones/:pfsense.cz/dns_records

echo "Create DNS AAAA record in domain pfsense.cz:"
cli4 --post name='starlink' type=AAAA content="2a0d:3344:1980:3d71:f2ad:4eff:fe28:adde" /zones/:pfsense.cz/dns_records

# EOF
