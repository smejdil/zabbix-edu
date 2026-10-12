#!/usr/bin/env bash
# Collect credentials from completed GCP training servers into one local file.
set -Eeuo pipefail
umask 077
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
PROJECT=${PROJECT:-datascript-zabbix-edu}
ZONE=${ZONE:-europe-central2-b}
OUTPUT=${OUTPUT:-$REPO_ROOT/files/zabbix-training-credentials.txt}
command -v gcloud >/dev/null

if (( $# )); then
    names=()
    for argument in "$@"; do
        if [[ $argument =~ ^[0-9]{2,3}$ ]]; then
            names+=("zbx$argument")
        elif [[ $argument =~ ^zbx[0-9]{2,3}$ ]]; then
            names+=("$argument")
        else
            echo "Invalid VM name: $argument" >&2
            exit 1
        fi
    done
else
    mapfile -t names < <(gcloud compute instances list --project="$PROJECT" \
        --filter='name~^zbx[0-9]+$' --format='value(name)')
fi
(( ${#names[@]} )) || { echo 'No Zabbix training VMs found.' >&2; exit 1; }
mkdir -p -- "$(dirname -- "$OUTPUT")"
output_tmp=$(mktemp "${OUTPUT}.XXXXXX")
trap 'rm -f -- "$output_tmp"' EXIT
{
    printf 'Zabbix EDU credentials\nProject: %s\nZone: %s\n\n' "$PROJECT" "$ZONE"
    for name in "${names[@]}"; do
        address=$(gcloud compute instances describe "$name" --project="$PROJECT" \
            --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
        [[ -n $address ]] || { echo "No external IPv4 for $name" >&2; exit 1; }
        mapfile -t values < <(gcloud --quiet compute ssh "$name" --project="$PROJECT" \
            --zone="$ZONE" --command='sudo -n cat /root/Done /root/zabbix-admin.pw /root/zbx-probe.pw /root/root-user.pw /root/zbx-user.pw')
        if (( ${#values[@]} != 5 )) || [[ ${values[0]} != Done\ * ]]; then
            echo "Installation or credential collection is incomplete on $name" >&2
            exit 1
        fi
        printf 'VM: %s\nURL: http://%s/zabbix/\nAdmin username: Admin\nAdmin password: %s\n' \
            "$name" "$address" "${values[1]}"
        printf 'Probe username: zbx_probe\nProbe password: %s\n' "${values[2]}"
        printf 'Linux root password: %s\nLinux zbx password: %s\n\n' "${values[3]}" "${values[4]}"
    done
} > "$output_tmp"
chmod 600 "$output_tmp"
mv -f -- "$output_tmp" "$OUTPUT"
trap - EXIT
printf 'Credentials saved to %s (mode 600).\n' "$OUTPUT"
