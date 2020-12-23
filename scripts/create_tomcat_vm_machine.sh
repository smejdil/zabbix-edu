#!/bin/bash
#
# Create GCP Linux server with Tomcat VM
#
# Lukas Maly <Iam@LukasMaly.NET> 4.12.2020
#

IMAGE_LIN=`gcloud compute images list | grep centos-7 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "linsrv${argv[j]}";
    gcloud compute instances create linsrv${argv[j]} --image ${IMAGE_LIN} --image-project=centos-cloud --zone=europe-west4-c --metadata-from-file startup-script=./zabbix-edu/scripts/install-tomcat-server.sh
    gcloud compute instances add-tags linsrv${argv[j]} --tags=http-server --zone=europe-west4-c
    gcloud compute instances add-tags linsrv${argv[j]} --tags=https-server --zone=europe-west4-c
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-agent --zone=europe-west4-c
    gcloud compute instances add-tags linsrv${argv[j]} --tags=zabbix-server --zone=europe-west4-c
    gcloud compute instances add-tags linsrv${argv[j]} --tags=snmp --zone=europe-west4-c
    gcloud compute instances add-tags linsrv${argv[j]} --tags=ipmi --zone=europe-west4-c
done

# gcloud compute regions list | grep europe-west

# europe-west1-b		St. Ghislain, Belgium, Europe
# europe-west1-c
# europe-west1-d

# europe-west2-a	London, England, Europe
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

# EOF
