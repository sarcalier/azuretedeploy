#!/bin/bash

#vars
CLIENT_BUILD_DIR=~/VMssBatchPatch/ss01


#creading the working directory if not yet
if [ ! -d "$CLIENT_BUILD_DIR" ]
    then mkdir -p "$CLIENT_BUILD_DIR"
fi

#CDing to the dir
cd "$CLIENT_BUILD_DIR"

#downloading manifests
echo "Downloading the terraform manifest"
wget -q https://raw.githubusercontent.com/sarcalier/azuretedeploy/dev/VMSSPatching/terraform/st02.1/main.tf -O main.tf


#playing the manifest
echo "Running the terraform manifest"
terraform init
terraform apply