#!/bin/sh
#
# List DNS record for Starlink
#
# Lukas Maly <Iam@LukasMaly.NET> 30.3.2023
#
clear

# There's the ability to handle dns entries with multiple values. This produces more than one API call within the command.

# starlink
echo "List DNS record starlink.pfsense.cz:"
cli4 /zones/:pfsense.cz/dns_records/:starlink.pfsense.cz | jq -c '.[]|{"id":.id,"name":.name,"type":.type,"content":.content}'

# EOF
