#!/bin/bash

echo "Running apt update"
apt-get update
echo "Installing nginx"
apt-get install nginx -y