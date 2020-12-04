#!/bin/bash
#
# Create GCP CentOS 8 VM
#
# Lukas Maly <Iam@LukasMaly.NET> 4.12.2020
#

IMAGE_CENTOS8=`gcloud compute images list | grep centos-8 | awk '{print $1}'`

argc=$#;
argv=("$@");

for (( j=0; j<argc; j++ )); do
    echo "zbx${argv[j]}";
    gcloud compute instances create zbx${argv[j]} --image ${IMAGE_CENTOS8} --image-project=centos-cloud --zone=europe-west1-c --metadata-from-file startup-script=./zabbix-edu/scripts/install-gcp.sh
    gcloud compute instances add-tags zbx${argv[j]} --tags=http-server --zone=europe-west1-c
    gcloud compute instances add-tags zbx${argv[j]} --tags=https-server --zone=europe-west1-c
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-agent --zone=europe-west1-c
    gcloud compute instances add-tags zbx${argv[j]} --tags=zabbix-server --zone=europe-west1-c
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
