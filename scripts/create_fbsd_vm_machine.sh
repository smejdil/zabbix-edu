#!/usr/bin/env bash
# Create FreeBSD training VMs with Zabbix agent installed at first boot.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-west4-a}
IMAGE=${IMAGE:-freebsd-15-0-release-amd64-ufs}

if (( $# == 0 )); then
    echo "Usage: $0 01 [02 ...]" >&2
    exit 1
fi

for number in "$@"; do
    [[ $number =~ ^[0-9]{2,3}$ ]] || { echo "Invalid VM number: $number" >&2; exit 1; }
    gcloud compute instances create "fbsdsrv${number}" \
        --project="$PROJECT" --zone="$ZONE" \
        --image="$IMAGE" --image-project=freebsd-org-cloud-dev \
        --tags=http-server,https-server,zabbix-agent,zabbix-server,snmp,ipmi,node-exporter,vault \
        --metadata-from-file="startup-script=$SCRIPT_DIR/install-freebsd-server.sh"
done
