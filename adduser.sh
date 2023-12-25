#!/usr/bin/env bash

# Step 1: Create a user named 'dima'
sudo useradd dima

# Step 2: Prompt for a password and assign it to the 'dima' user
read -s -p "Enter password for dima user: " dima_password
echo "dima:$dima_password" | sudo chpasswd

# Step 3: Assign root rights to the 'dima' user
sudo usermod -aG sudo dima

# Step 4: Add SSH key to the home folder of the 'dima' user
sudo su - dima -c "mkdir -p ~/.ssh && wget -O - https://github.com/patrondumitru.keys >> ~/.ssh/authorized_keys"

# Step 5: Enable SSH public key authentication in the SSH server config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo service ssh restart

echo "Script executed successfully."
