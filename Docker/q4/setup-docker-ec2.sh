#!/bin/bash

set -e

echo "Updating packages..."

sudo apt update -y

echo "Installing Docker..."

sudo apt install docker.io -y

echo "Starting Docker..."

sudo systemctl enable docker
sudo systemctl start docker

echo "Adding current user to Docker group..."

sudo usermod -aG docker "$USER"

echo
echo "Docker installation completed."

docker --version || true

echo
echo "Log out and log back in for Docker group changes to take effect."
