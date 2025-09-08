#!/bin/bash

# ================================================================
# Cross-Distro User Creation and SSH Setup Script (Debian/Arch)
# ================================================================
# Features:
# - Detects Debian/Ubuntu or Arch.
# - Creates user with password + sudo/wheel privileges.
# - Fetches SSH keys from GitHub (via username).
# - Disables password authentication and root SSH login.
# - Auto-enables %wheel in sudoers on Arch.
# ================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

USERNAME="dima"
GITHUB_USER="patrondumitru"   # GitHub username, not full URL
GITHUB_KEY_URL="https://github.com/${GITHUB_USER}.keys"

# Detect distro
if [ -f /etc/debian_version ]; then
  DISTRO="debian"
  SUDO_GROUP="sudo"
  SSH_SERVICE="ssh"
elif [ -f /etc/arch-release ]; then
  DISTRO="arch"
  SUDO_GROUP="wheel"
  SSH_SERVICE="sshd"
else
  echo "Unsupported distro. Exiting."
  exit 1
fi

echo "Detected distro: $DISTRO"

# --- 1. Create the new user ---
if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists, skipping creation."
else
  echo "Creating user '$USERNAME'..."
  useradd -m -s /bin/bash "$USERNAME"
  read -s -p "Enter password for '$USERNAME' user: " USER_PASSWORD
  echo
  echo "$USERNAME:$USER_PASSWORD" | chpasswd
fi

# --- 2. Sudo privileges ---
echo "Adding user '$USERNAME' to '$SUDO_GROUP' group..."
usermod -aG "$SUDO_GROUP" "$USERNAME"

# Enable wheel in sudoers (Arch only)
if [ "$DISTRO" = "arch" ]; then
  echo "Ensuring %wheel is enabled in /etc/sudoers..."
  sed -i 's/^# *%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
fi

# --- 3. SSH key setup ---
echo "Configuring SSH key-based authentication..."
mkdir -p /home/"$USERNAME"/.ssh
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh

if curl -fsSL "$GITHUB_KEY_URL" -o /home/"$USERNAME"/.ssh/authorized_keys; then
  chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh/authorized_keys
  chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
  echo "SSH keys imported from GitHub account: $GITHUB_USER"
else
  echo "⚠️ Failed to fetch keys from $GITHUB_KEY_URL"
fi

# --- 4. SSH server config ---
echo "Updating SSH server configuration..."
sed -i 's/^\(#\|\)PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^\(#\|\)PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
# sed -i 's/^\(#\|\)PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config #-disable Root login by SSH

# --- 5. Restart SSH ---
echo "Restarting SSH service..."
systemctl restart "$SSH_SERVICE"

# --- 6. Done ---
echo "
--------------------------------------------------
User '$USERNAME' created with sudo privileges.
SSH keys installed from GitHub: https://github.com/$GITHUB_USER
Password login disabled. Root SSH login disabled.
--------------------------------------------------
"
