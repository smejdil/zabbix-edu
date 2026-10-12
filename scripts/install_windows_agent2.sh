#!/usr/bin/env bash
# Configure one Windows training VM through an IAP tunnel and Ansible.
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-west4-a}
WINRM_LOCAL_PORT=${WINRM_LOCAL_PORT:-15986}
WINDOWS_USER=${WINDOWS_USER:-ansible}

if (( $# != 1 )) || [[ ! $1 =~ ^[0-9]{2,3}$ ]]; then
    echo "Usage: $0 01" >&2
    exit 1
fi
VM_NAME="winsrv${1}"
if [[ -z ${WINDOWS_PASSWORD:-} ]]; then
    read -r -s -p "Windows password for ${WINDOWS_USER}@${VM_NAME}: " WINDOWS_PASSWORD
    printf '\n'
fi
[[ -n $WINDOWS_PASSWORD ]] || { echo 'Windows password is empty.' >&2; exit 1; }
export WINDOWS_USER WINDOWS_PASSWORD WINRM_LOCAL_PORT

command -v gcloud >/dev/null
command -v ansible-playbook >/dev/null
TUNNEL_LOG=$(mktemp)
TUNNEL_PID=
cleanup() {
    if [[ -n $TUNNEL_PID ]]; then
        kill "$TUNNEL_PID" 2>/dev/null || true
        wait "$TUNNEL_PID" 2>/dev/null || true
    fi
    rm -f -- "$TUNNEL_LOG"
}
trap cleanup EXIT

gcloud compute start-iap-tunnel "$VM_NAME" 5986 \
    --project="$PROJECT" --zone="$ZONE" \
    --local-host-port="localhost:${WINRM_LOCAL_PORT}" >"$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!
for (( attempt=0; attempt<30; attempt++ )); do
    if (echo > "/dev/tcp/127.0.0.1/${WINRM_LOCAL_PORT}") >/dev/null 2>&1; then
        break
    fi
    if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
        cat "$TUNNEL_LOG" >&2
        exit 1
    fi
    sleep 1
done
if ! (echo > "/dev/tcp/127.0.0.1/${WINRM_LOCAL_PORT}") >/dev/null 2>&1; then
    cat "$TUNNEL_LOG" >&2
    echo 'IAP tunnel did not become ready.' >&2
    exit 1
fi

ansible-playbook -i "${VM_NAME}," "$SCRIPT_DIR/../zabbix/ansible/install-windows-agent2.yml"
