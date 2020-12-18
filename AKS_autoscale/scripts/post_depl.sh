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
wget -q https://raw.githubusercontent.com/nginxinc/docker-nginx/aa41ddeef871b7f0ea64a44f26d3f4aa0e6d5e7b/mainline/alpine/10-listen-on-ipv6-by-default.sh
wget -q https://raw.githubusercontent.com/nginxinc/docker-nginx/aa41ddeef871b7f0ea64a44f26d3f4aa0e6d5e7b/mainline/alpine/20-envsubst-on-templates.sh
wget -q https://raw.githubusercontent.com/nginxinc/docker-nginx/aa41ddeef871b7f0ea64a44f26d3f4aa0e6d5e7b/mainline/alpine/Dockerfile
wget -q https://raw.githubusercontent.com/nginxinc/docker-nginx/aa41ddeef871b7f0ea64a44f26d3f4aa0e6d5e7b/mainline/alpine/docker-entrypoint.sh

#Xing the scripts
chmod +x docker-entrypoint.sh
chmod +x 10-listen-on-ipv6-by-default.sh
chmod +x 20-envsubst-on-templates.sh

#building the container
docker build . -t nginx_alpine
docker run --name nginx -d -p 80:80 nginx_alpine