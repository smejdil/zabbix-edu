#!/bin/bash
#
# Create GCP Windows server VM
#
# Lukas Maly <Iam@LukasMaly.NET> 11.11.2020
#

IMAGE_WIN=`gcloud compute images list --project windows-cloud --no-standard-images | grep dc-v | grep 2019 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "winsrv${argv[j]}";
    gcloud compute instances create winsrv${argv[j]} --image ${IMAGE_WIN} --image-project=windows-cloud --metadata-from-file startup-script=./zabbix-edu/scripts/firewall-zabbix-agent.ps1
    gcloud compute instances add-tags winsrv${argv[j]} --tags=http-server
    gcloud compute instances add-tags winsrv${argv[j]} --tags=https-server
    gcloud compute instances add-tags winsrv${argv[j]} --tags=zabbix-agent
    gcloud compute instances add-tags winsrv${argv[j]} --tags=zabbix-server
done

# EOF
