#!/bin/bash
#
# Create GCP CentOS 8 vm
#
# Lukas Maly <Iam@LukasMaly.NET> 5.11.2020
#

IMAGE_CENTOS8=`gcloud compute images list | grep centos-8 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "zbx${argv[j]}";
    gcloud compute instances create zbx${argv[j]} --image ${IMAGE_CENTOS8} --image-project=centos-cloud
    gcloud compute instances add-tags zbx${argv[j]} --tags=http-server
    gcloud compute instances add-tags zbx${argv[j]} --tags=https-server
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-agent
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-server
done

# EOF
