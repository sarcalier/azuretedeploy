#!/bin/bash

#vars
CLIENT_BUILD_DIR=~/VMssDeploy/


#creading the working directory if not yet
if [ ! -d "$CLIENT_BUILD_DIR" ]
    then mkdir "$CLIENT_BUILD_DIR"
fi

#CDing to the dir
(
cd "$CLIENT_BUILD_DIR"
)
echo $(pwd)