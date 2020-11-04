#!/bin/bash
#
# Create GCP CentOS 8 vm
#

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "zbx${argv[j]}";
    gcloud compute instances create zbx${argv[j]} --image centos-8-v20201014 --image-project=centos-cloud
    gcloud compute instances add-tags zbx${argv[j]} --tags=http-server
    gcloud compute instances add-tags zbx${argv[j]} --tags=https-server
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-agent
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-server
done

# EOF
