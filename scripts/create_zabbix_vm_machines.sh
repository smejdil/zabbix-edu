#!/usr/bin/env bash
# Create Ubuntu 26.04 training VMs and run the installer at first boot.
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-central2-b}
IMAGE_FAMILY=${IMAGE_FAMILY:-ubuntu-2604-lts-amd64}
MACHINE_TYPE=${MACHINE_TYPE:-e2-medium}
BOOT_DISK_SIZE=${BOOT_DISK_SIZE:-30GB}
if (( $# == 0 )); then
    echo "Usage: $0 01 [02 ...]" >&2
    exit 1
fi
command -v gcloud >/dev/null
for number in "$@"; do
    [[ $number =~ ^[0-9]{2,3}$ ]] || { echo "Invalid VM number: $number" >&2; exit 1; }
done
for number in "$@"; do
    gcloud compute instances create "zbx${number}" \
        --project="$PROJECT" --zone="$ZONE" \
        --image-family="$IMAGE_FAMILY" --image-project=ubuntu-os-cloud \
        --machine-type="$MACHINE_TYPE" --boot-disk-size="$BOOT_DISK_SIZE" \
        --tags=http-server,https-server,zabbix-agent,zabbix-server,node-exporter \
        --metadata-from-file="startup-script=${SCRIPT_DIR}/install-zabbix-gcp.sh"
done
