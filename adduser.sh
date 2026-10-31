#!/bin/bash

# ================================================================
# Universal admin-user + SSH setup (Debian/Ubuntu/Proxmox, Arch)
# ================================================================
# - Creates the user (default: dima) with sudo/wheel and, optionally, a password.
# - Imports public keys from https://github.com/<GITHUB_USER>.keys (+ EXTRA_PUBKEY),
#   for the user and, optionally, for root.
# - Asks (or reads env vars) whether to disable SSH password login and what to do
#   with root SSH login. Defaults change nothing that is already working.
# - On Proxmox VE: optionally adds <user>@pam as Administrator in the web UI.
#
# Every question can be preset with an environment variable, which also makes the
# script non-interactive (stdin not a terminal -> defaults are used):
#   USERNAME=dima  GITHUB_USER=patrondumitru  EXTRA_PUBKEY="ssh-ed25519 AAAA... lab-admin"
#   ROOT_KEYS=y|n            add the keys to /root/.ssh/authorized_keys      (default y)
#   SUDO_NOPASSWD=y|n        passwordless sudo for the user                  (default n)
#   SSH_PASSWORD_AUTH=keep|disable   SSH password login                      (default keep)
#   ROOT_LOGIN=keep|key-only|no      root SSH login                          (default keep)
#   PVE_ADMIN=y|n            Proxmox web UI administrator (only if pveum)    (default y)
# ================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (or with sudo)."
  exit 1
fi

USERNAME="${USERNAME:-dima}"
GITHUB_USER="${GITHUB_USER:-patrondumitru}"   # GitHub username, not full URL
GITHUB_KEY_URL="https://github.com/${GITHUB_USER}.keys"
EXTRA_PUBKEY="${EXTRA_PUBKEY:-}"

# ask VAR "question" default: keep a preset value, else prompt on a terminal, else use default
ask() {
  local var=$1 question=$2 default=$3 answer
  [ -n "${!var:-}" ] && return
  if [ -t 0 ]; then
    read -r -p "$question [$default]: " answer
    answer="${answer:-$default}"
  else
    answer="$default"
  fi
  printf -v "$var" '%s' "$(echo "$answer" | tr '[:upper:]' '[:lower:]')"
}

# Detect distro
if [ -f /etc/debian_version ]; then
  DISTRO="debian"; SUDO_GROUP="sudo"; SSH_SERVICE="ssh"
elif [ -f /etc/arch-release ]; then
  DISTRO="arch"; SUDO_GROUP="wheel"; SSH_SERVICE="sshd"
else
  echo "Unsupported distro. Exiting."
  exit 1
fi
echo "Detected distro: $DISTRO"

ask ROOT_KEYS "Add the keys to root's authorized_keys too? (y/n)" y
ask SUDO_NOPASSWD "Passwordless sudo for $USERNAME? (y/n)" n
ask SSH_PASSWORD_AUTH "SSH password login: keep or disable? (keep/disable)" keep
ask ROOT_LOGIN "Root SSH login: keep, key-only or no? (keep/key-only/no)" keep
HAS_PVE=no; command -v pveum >/dev/null 2>&1 && HAS_PVE=yes
[ "$HAS_PVE" = yes ] && ask PVE_ADMIN "Add ${USERNAME}@pam as Proxmox Administrator? (y/n)" y

add_key() {  # add_key <file> <key line>: append only if missing
  grep -qxF "$2" "$1" 2>/dev/null || echo "$2" >> "$1"
}

# --- 1. User + sudo ---
if [ "$DISTRO" = "debian" ] && ! command -v sudo >/dev/null 2>&1; then
  apt-get install -y sudo
fi

HAS_PASSWORD=no
if id "$USERNAME" &>/dev/null; then
  echo "User '$USERNAME' already exists, skipping creation."
  HAS_PASSWORD=yes
else
  echo "Creating user '$USERNAME'..."
  useradd -m -s /bin/bash "$USERNAME"
  if [ -t 0 ]; then
    read -r -s -p "Password for '$USERNAME' (empty = none, key only): " USER_PASSWORD; echo
    if [ -n "$USER_PASSWORD" ]; then
      echo "$USERNAME:$USER_PASSWORD" | chpasswd && HAS_PASSWORD=yes
    fi
  fi
fi
usermod -aG "$SUDO_GROUP" "$USERNAME"

# Without a password sudo would be unusable, so passwordless sudo is forced.
if [ "$HAS_PASSWORD" = no ]; then SUDO_NOPASSWD=y; fi
if [ "$SUDO_NOPASSWD" = y ]; then
  echo "$USERNAME ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$USERNAME"
  chmod 440 "/etc/sudoers.d/90-$USERNAME"
fi
if [ "$DISTRO" = "arch" ]; then
  sed -i 's/^# *%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
fi

# --- 2. SSH keys ---
KEYS="$(curl -fsSL "$GITHUB_KEY_URL" 2>/dev/null || true)"
[ -n "$KEYS" ] || echo "Warning: no keys fetched from $GITHUB_KEY_URL"

install_keys() {  # install_keys <authorized_keys file>
  touch "$1"; chmod 600 "$1"
  echo "$KEYS" | while read -r line; do [ -n "$line" ] && add_key "$1" "$line"; done
  [ -n "$EXTRA_PUBKEY" ] && add_key "$1" "$EXTRA_PUBKEY"
  return 0
}

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
mkdir -p "$USER_HOME/.ssh"
install_keys "$USER_HOME/.ssh/authorized_keys"
chown -R "$USERNAME":"$(id -gn "$USERNAME")" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
HAS_KEYS=no; [ -s "$USER_HOME/.ssh/authorized_keys" ] && HAS_KEYS=yes

if [ "$ROOT_KEYS" = y ]; then
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  install_keys /root/.ssh/authorized_keys
  echo "Keys added to root."
fi

# --- 3. SSH server config (drop-in, validated before restart) ---
if [ "$SSH_PASSWORD_AUTH" = disable ]; then
  if [ "$HAS_KEYS" = no ]; then
    echo "No SSH keys installed: keeping password login so you are not locked out."
    SSH_PASSWORD_AUTH=keep
  elif command -v pvecm >/dev/null 2>&1 && ! pvecm status >/dev/null 2>&1 && [ -t 0 ]; then
    read -r -p "This Proxmox node is not in a cluster yet; 'pvecm add' needs SSH password login. Disable anyway? (y/n) [n]: " go
    [ "${go:-n}" = y ] || SSH_PASSWORD_AUTH=keep
  fi
fi

DROPIN=/etc/ssh/sshd_config.d/10-adduser.conf
mkdir -p /etc/ssh/sshd_config.d
grep -qE '^\s*Include\s+/etc/ssh/sshd_config.d/' /etc/ssh/sshd_config \
  || echo "Warning: sshd_config has no Include for sshd_config.d; add it for the drop-in to apply."
{
  echo "PubkeyAuthentication yes"
  [ "$SSH_PASSWORD_AUTH" = disable ] && echo "PasswordAuthentication no"
  case "$ROOT_LOGIN" in
    key-only) echo "PermitRootLogin prohibit-password" ;;
    no)       echo "PermitRootLogin no" ;;
  esac
} > "$DROPIN"
if sshd -t 2>/dev/null; then
  systemctl restart "$SSH_SERVICE"
else
  echo "sshd config test failed, removing $DROPIN (SSH unchanged)."
  rm -f "$DROPIN"
fi

# --- 4. Proxmox web UI administrator ---
if [ "$HAS_PVE" = yes ] && [ "${PVE_ADMIN:-n}" = y ]; then
  pveum user list 2>/dev/null | grep -q "${USERNAME}@pam" || pveum user add "${USERNAME}@pam"
  pveum acl modify / --users "${USERNAME}@pam" --roles Administrator
  echo "Proxmox: ${USERNAME}@pam is Administrator (shared across the cluster)."
fi

echo "
--------------------------------------------------
User:            $USERNAME (group $SUDO_GROUP, passwordless sudo: $SUDO_NOPASSWD)
Keys from:       https://github.com/$GITHUB_USER ${EXTRA_PUBKEY:+(+ extra key)}
Root keys:       $ROOT_KEYS
SSH password:    $SSH_PASSWORD_AUTH
Root SSH login:  $ROOT_LOGIN
Proxmox admin:   ${PVE_ADMIN:-n/a}
--------------------------------------------------
"
