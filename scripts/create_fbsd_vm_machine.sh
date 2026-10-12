#!/usr/bin/env bash
# Create FreeBSD training VMs with a guaranteed SSH bootstrap user.
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-west4-a}
IMAGE=${IMAGE:-freebsd-15-1-release-amd64-ufs}
SSH_USER=${SSH_USER:-$(id -un)}
SSH_PUBLIC_KEY_FILE=${SSH_PUBLIC_KEY_FILE:-$HOME/.ssh/google_compute_engine.pub}
SSH_PRIVATE_KEY_FILE=${SSH_PRIVATE_KEY_FILE:-${SSH_PUBLIC_KEY_FILE%.pub}}
if (( $# == 0 )); then
    echo "Usage: $0 01 [02 ...]" >&2
    exit 1
fi
[[ $SSH_USER =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Invalid SSH user: $SSH_USER" >&2; exit 1; }
[[ -r $SSH_PUBLIC_KEY_FILE ]] || { echo "Missing public key: $SSH_PUBLIC_KEY_FILE" >&2; exit 1; }
[[ -r $SSH_PRIVATE_KEY_FILE ]] || { echo "Missing private key: $SSH_PRIVATE_KEY_FILE" >&2; exit 1; }
read -r key_type key_body _ < "$SSH_PUBLIC_KEY_FILE"
[[ $key_type == ssh-rsa || $key_type == ssh-ed25519 || $key_type == ecdsa-sha2-* ]] || {
    echo "Unsupported SSH public key type: $key_type" >&2; exit 1;
}
[[ $key_body =~ ^[A-Za-z0-9+/=]+$ ]] || { echo 'Invalid SSH public key.' >&2; exit 1; }
for number in "$@"; do
    [[ $number =~ ^[0-9]{2,3}$ ]] || { echo "Invalid VM number: $number" >&2; exit 1; }
done
command -v gcloud >/dev/null
startup_file=$(mktemp)
ssh_keys_file=$(mktemp)
trap 'rm -f -- "$startup_file" "$ssh_keys_file"' EXIT
{
    printf '#!/bin/sh\nEDU_SSH_USER=%s\nEDU_SSH_PUBLIC_KEY="%s %s"\n' "$SSH_USER" "$key_type" "$key_body"
    tail -n +2 "$SCRIPT_DIR/install-freebsd-server.sh"
} > "$startup_file"
# The guest agent manages authorized_keys from this metadata. Keep the same key
# in the startup script as a fallback if account provisioning is delayed.
printf '%s:%s %s\n' "$SSH_USER" "$key_type" "$key_body" > "$ssh_keys_file"
for number in "$@"; do
    gcloud compute instances create "fbsdsrv${number}" \
        --project="$PROJECT" --zone="$ZONE" \
        --image="$IMAGE" --image-project=freebsd-org-cloud-dev \
        --tags=http-server,https-server,zabbix-agent,zabbix-server,snmp,ipmi,node-exporter,vault \
        --metadata=enable-oslogin=FALSE \
        --metadata-from-file="startup-script=$startup_file,ssh-keys=$ssh_keys_file"
done
