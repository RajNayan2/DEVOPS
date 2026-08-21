#!/bin/bash

set -e

echo "Updating system..."

sudo apt update -y

echo "Installing Docker..."

sudo apt install -y docker.io

sudo systemctl enable docker
sudo systemctl start docker

echo "Pulling Nginx..."

sudo docker pull nginx

echo "Pulling MySQL..."

sudo docker pull mysql

echo "Running Nginx..."

sudo docker run -d \
    --name nginx-container \
    -p 80:80 \
    nginx

echo "Running MySQL..."

sudo docker run -d \
    --name mysql-container \
    -e MYSQL_ROOT_PASSWORD=RootPassword123 \
    mysql

echo "Nginx and MySQL containers started."

sudo docker ps
