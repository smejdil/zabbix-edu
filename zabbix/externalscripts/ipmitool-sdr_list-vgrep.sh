#!/bin/sh

if [ $# -lt 6 ]; then
  echo "  usage $0 <HOST> <USERNAME> <PASSWORD> <PRIVILEGE_LEVEL> <AUTHENTICATION PROTOCOL> <FILTER(out)_STRING>"
  exit 1
fi
 
HOST=$1
USER=$2
PASS=$3
LEVEL=$4
AUTH=$5
FILTER=$6
echo "List of IPMI sensors:"
ipmitool -H $HOST -U $USER -P $PASS -L $LEVEL -A $AUTH sdr list all 2>/dev/null | egrep -v "ns$|$FILTER$"
echo "Execution of ipmitool finished [RC=$?]"

# EOF
