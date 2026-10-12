#!/usr/bin/env bash
# Create Windows Server 2019 training VMs and prepare WinRM for Ansible over IAP.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-west4-a}
IMAGE_FAMILY=${IMAGE_FAMILY:-windows-2019}
WINRM_FIREWALL_RULE=${WINRM_FIREWALL_RULE:-allow-zabbix-edu-winrm-iap}

if (( $# == 0 )); then
    echo "Usage: $0 01 [02 ...]" >&2
    exit 1
fi
for number in "$@"; do
    [[ $number =~ ^[0-9]{2,3}$ ]] || { echo "Invalid VM number: $number" >&2; exit 1; }
done

# Ansible reaches WinRM through an IAP tunnel. Open only the IAP source range.
if ! gcloud compute firewall-rules describe "$WINRM_FIREWALL_RULE" --project="$PROJECT" >/dev/null 2>&1; then
    gcloud compute firewall-rules create "$WINRM_FIREWALL_RULE" \
        --project="$PROJECT" --network=default --direction=INGRESS \
        --action=ALLOW --rules=tcp:5986 \
        --source-ranges=35.235.240.0/20 --target-tags=zabbix-edu-winrm
fi

for number in "$@"; do
    gcloud compute instances create "winsrv${number}" \
        --project="$PROJECT" --zone="$ZONE" \
        --image-family="$IMAGE_FAMILY" --image-project=windows-cloud \
        --tags=http-server,https-server,zabbix-agent,zabbix-server,zabbix-edu-winrm \
        --metadata-from-file="sysprep-specialize-script-ps1=$SCRIPT_DIR/windows-configure.ps1"
done
