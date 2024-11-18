#!/bin/bash

# Should it be necessary, this script will undo everything d
# one by the Oncoanalyser setup script

echo "Undoing everything done by the Oncoanalyser setup script..."

# Remove tmux
sudo apt-get remove --purge -y tmux

# Remove unzip and zip
sudo apt-get remove --purge -y unzip zip

# Remove Java (SDKMAN)
rm -rf ~/.sdkman
sed -i '/sdkman/d' ~/.bashrc

# Remove Docker
sudo systemctl stop docker
sudo apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /etc/docker /var/run/docker.sock /etc/apt/keyrings/docker.gpg
sudo groupdel docker

# Undo Docker group membership
sudo gpasswd -d $(whoami) docker

# Remove Nextflow
rm -f ~/.local/bin/nextflow
rm -rf ~/.nextflow

# Restore PATH modifications
sed -i '/export PATH="$HOME\/.local\/bin:$PATH"/d' ~/.bashrc
source ~/.bashrc

# Remove cloned repositories
rm -rf ~/.nextflow/assets/nf-core/oncoanalyser

# Remove logs
rm -f oncoanalyser_setup.log oncoanalyser_setup.out oncoanalyser_setup.err

# Clean reference data
rm -rf prepare_reference/

echo "Undo completed. You can now run the script again from scratch if needed."