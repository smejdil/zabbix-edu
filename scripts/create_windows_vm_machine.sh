#!/bin/bash
#
# Create GCP Windows server VM
#
# Lukas Maly <Iam@LukasMaly.NET> 9.111.2021
#

# GCP Set project Zabbix-EDU
REGION="europe-central2"
ZONE="europe-central2-a"
PROJECT="datascript-zabbix-edu"

gcloud config set project ${PROJECT}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${ZONE}

IMAGE_WIN=`gcloud compute images list --project windows-cloud --no-standard-images | grep dc-v | grep 2019 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "winsrv${argv[j]}";
    gcloud compute instances create winsrv${argv[j]} --image ${IMAGE_WIN} --image-project=windows-cloud --zone=${ZONE} --metadata-from-file startup-script=./zabbix-edu/scripts/windows-configure.ps1
    gcloud compute instances add-tags winsrv${argv[j]} --tags=http-server --zone=${ZONE}
    gcloud compute instances add-tags winsrv${argv[j]} --tags=https-server --zone=${ZONE}
    gcloud compute instances add-tags winsrv${argv[j]} --tags=zabbix-agent --zone=${ZONE}
    gcloud compute instances add-tags winsrv${argv[j]} --tags=zabbix-server --zone=${ZONE}
done

# gcloud compute regions list | grep europe-west

# europe-west1-b		St. Ghislain, Belgium, Europe
# europe-west1-c
# europe-west1-d

# europe-west2-a		London, England, Europe
# europe-west2-b
# europe-west2-c

# europe-west3-a		Frankfurt, Germany Europe
# europe-west3-b
# europe-west3-c

# europe-west4-a		Eemshaven, Netherlands, Europe
# europe-west4-b
# europe-west4-c

# europe-west6-a		Zurich, Switzerland, Europe
# europe-west6-b
# europe-west6-c

# europe-central2-a		Warsaw, Poland, Europe
# europe-central2-b
# europe-central2-c

# EOF
