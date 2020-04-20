#!/bin/bash

echo "Creating the directory"
mkdir tf-deploy-proc-mon
cd tf-deploy-proc-mon
echo "Downloading the terraform manifest"
wget "https://raw.githubusercontent.com/sarcalier/azuretedeploy/dev/ProcessMonitor/terraform/main.tf"
echo "Running the terraform manifest"
terraform init
terraform apply