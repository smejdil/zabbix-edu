#!/bin/bash
#
# Create GCP Linux server with Tomcat VM
#
# Lukas Maly <Iam@LukasMaly.NET> 1.9.2021
#

# GCP Set project Zabbix-EDU
gcloud config set project datascript-zabbix-edu

IMAGE_LIN=`gcloud compute images list | grep centos-7 | awk '{print $1}'`
ZONE="europe-central2-c"

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "linsrv${argv[j]}";
    gcloud compute instances create linsrv${argv[j]} --image ${IMAGE_LIN} --image-project=centos-cloud --zone=${ZONE} --metadata-from-file startup-script=./zabbix-edu/scripts/install-tomcat-server.sh
    gcloud compute instances add-tags linsrv${argv[j]} --tags=http-server --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=https-server --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-agent --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-server --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=snmp --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=ipmi --zone=${ZONE}
    gcloud compute instances add-tags linsrv${argv[j]} --tags=node-exporter --zone=${ZONE}
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
