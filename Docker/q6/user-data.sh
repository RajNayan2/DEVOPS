#!/bin/bash

apt-get update -y

apt-get install docker.io -y

systemctl enable docker
systemctl start docker

docker run -d \
    --name getting-started \
    -p 80:80 \
    docker/getting-started
