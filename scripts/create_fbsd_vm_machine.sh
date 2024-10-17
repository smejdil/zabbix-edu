#!/bin/bash
#
# Create GCP FreeBSD server for Zabbix API
#
# Lukas Maly <Iam@LukasMaly.NET> 17.10.2024
#

# GCP Set project Zabbix-EDU
REGION="europe-central2"
ZONE="europe-central2-a"
PROJECT="datascript-zabbix-edu"

gcloud config set project ${PROJECT}
gcloud config set compute/region ${REGION}
gcloud config set compute/zone ${ZONE}

FBSD="14-1"
#IMAGE_FBD=`gcloud compute images list | grep bsd | awk '{print $1}'`
# gcloud compute images list --project=freebsd-org-cloud-dev --no-standard-images | grep release-amd64
# freebsd-14-0-release-amd64-ufs

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "fbsdsrv${argv[j]}";
    gcloud compute instances create fbsdsrv${argv[j]} --image freebsd-${FBSD}-release-amd64-ufs --image-project=freebsd-org-cloud-dev --zone=${ZONE} --metadata-from-file startup-script=./zabbix-edu/scripts/install-freebsd-server.sh
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=http-server --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=https-server --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=zabbix-agent --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=zabbix-server --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=snmp --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=ipmi --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=node-exporter --zone=${ZONE}
    gcloud compute instances add-tags fbsdsrv${argv[j]} --tags=vault --zone=${ZONE}
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
