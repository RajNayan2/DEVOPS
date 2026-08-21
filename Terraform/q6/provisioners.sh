#!/bin/bash

set -e

sudo apt-get update -y
sudo apt-get install -y nginx

sudo systemctl enable nginx
sudo systemctl start nginx

echo "<h1>Nginx installed using Terraform provisioners</h1>" | \
sudo tee /var/www/html/index.html

echo "Nginx installation completed."
