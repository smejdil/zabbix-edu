#!/bin/bash
#
# Create GCP Linux server with Tomcat VM
#
# Lukas Maly <Iam@LukasMaly.NET> 11.11.2020
#

IMAGE_LIN=`gcloud compute images list | grep centos-7 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "winsrv${argv[j]}";
    gcloud compute instances create linsrv${argv[j]} --image ${IMAGE_LIN} --image-project=centos-cloud  --metadata-from-file startup-script=scripts/install-tomcat-server.sh
    gcloud compute instances add-tags linsrv${argv[j]} --tags=http-server
    gcloud compute instances add-tags linsrv${argv[j]} --tags=https-server
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-agent
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-server
done

# EOF
