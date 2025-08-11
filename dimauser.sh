#!/bin/bash

# ================================================================
# Updated Bash Script for User Creation and SSH Setup
# ================================================================
# This script automates user creation and SSH configuration,
# incorporating best practices for security and permissions.
#
# USAGE:
# 1. Ensure you have the correct GitHub URL for the public keys.
# 2. Run the script with sudo: `sudo ./create_user.sh`.
#
# The script will:
# - Create a new user 'dima'.
# - Prompt for a password and set it securely.
# - Add the user to the 'sudo' group.
# - Fetch the public key from the provided GitHub URL.
# - Correctly set permissions for the .ssh directory and
#   the authorized_keys file, which is crucial for SSH to work.
# - Disable password authentication in sshd_config.
# - Restart the SSH service to apply changes.
# ================================================================

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Define the username and the GitHub key URL
USERNAME="dima"
GITHUB_KEY_URL="https://github.com/patrondumitru.keys"

# --- 1. Create the new user ---
echo "Creating user '$USERNAME'..."
# The -m flag creates the user's home directory
# The -s /bin/bash flag sets the default shell to Bash
useradd -m -s /bin/bash "$USERNAME"

# --- 2. Prompt for a password and assign it ---
read -s -p "Enter password for '$USERNAME' user: " USER_PASSWORD
echo
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# --- 3. Grant administrative privileges with sudo ---
echo "Adding user '$USERNAME' to the 'sudo' group..."
usermod -aG sudo "$USERNAME"

# --- 4. Add SSH key and set permissions ---
echo "Configuring SSH key-based authentication..."
# Create the .ssh directory and set ownership and permissions
sudo mkdir -p /home/"$USERNAME"/.ssh
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
sudo chmod 700 /home/"$USERNAME"/.ssh

# Fetch the public key from GitHub and add it to authorized_keys
# Use curl instead of wget for a more widely available tool
sudo -u "$USERNAME" sh -c "curl -sL $GITHUB_KEY_URL > ~/.ssh/authorized_keys"

# Set the correct permissions on the authorized_keys file
sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

# --- 5. Modify the SSH server configuration ---
echo "Updating SSH server configuration..."
# Use sed to disable password authentication and enable pubkey authentication
# The sed commands are idempotent, meaning they can be run multiple times safely
sudo sed -i 's/^\(#\|\)PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^\(#\|\)PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# --- 6. Restart the SSH service ---
echo "Restarting SSH service..."
sudo service ssh restart

# --- 7. Final message ---
echo "
--------------------------------------------------
Script executed successfully!
User '$USERNAME' has been created with sudo privileges.
You can now log in using your private key.
Password authentication is disabled for better security.
--------------------------------------------------"

exit 0
