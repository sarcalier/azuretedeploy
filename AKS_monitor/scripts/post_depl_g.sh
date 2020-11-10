#!/bin/bash

#vars
CLIENT_BUILD_DIR=~/nginx/


#installing docker
apt-get update && apt-get install -y docker.io && systemctl start docker && systemctl enable docker


#creading the working directory if not yet
if [ ! -d "$CLIENT_BUILD_DIR" ]
    then mkdir "$CLIENT_BUILD_DIR"
fi

#CDing to the dir
cd "$CLIENT_BUILD_DIR"

#downloading manifests
echo "Downloading the docker files"
wget -q https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/AKS_monitor/scripts/custom_img/10-listen-on-ipv6-by-default.sh
wget -q https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/AKS_monitor/scripts/custom_img/20-envsubst-on-templates.sh
wget -q https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/AKS_monitor/scripts/custom_img/Dockerfile
wget -q https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/AKS_monitor/scripts/custom_img/docker-entrypoint.sh

#Xing the scripts
chmod +x docker-entrypoint.sh
chmod +x 10-listen-on-ipv6-by-default.sh
chmod +x 20-envsubst-on-templates.sh

#building the container
docker build . -t nginx_exp
docker run --name nginx -d --network host nginx_exp