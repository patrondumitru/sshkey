# SSHKey Repository

This repository contains a script (`adduser.sh`) that automates the process of creating a user, assigning root rights, setting a password, adding an SSH key, and enabling SSH public key authentication on a Linux machine.

## Instructions for Using `adduser.sh` Script

### Usage locally

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/patrondumitru/sshkey.git

2. **Navigate to the Directory:**
   ```bash
   cd sshkey

2. **Run the Script:**
   ```bash
   bash adduser.sh


### Usage remote script

1. **Run in terminal this line:**
   ```bash
   bash -c "$(wget -qLO - https://github.com/patrondumitru/sshkey/raw/main/adduser.sh)"

2. **Navigate to the Directory:**
   ```bash
   cd sshkey

2. **Run the Script:**
   ```bash
   bash adduser.sh


Copy this file to your Linux Machine and run this command
chmod +x setup_dima_user.sh

or
Run in terminal this line
bash -c "$(wget -qLO - https://github.com/patrondumitru/sshkey/adduser.sh)"

## Options

The script asks a few questions on a terminal. Each one can be preset with an environment
variable, which also makes it non-interactive (defaults are used when stdin is not a terminal).

| Variable | Default | Effect |
|---|---|---|
| `USERNAME` | `dima` | user to create |
| `GITHUB_USER` | `patrondumitru` | keys are fetched from `https://github.com/<user>.keys` |
| `EXTRA_PUBKEY` | empty | one more public key, added for the user and for root |
| `ROOT_KEYS` | `y` | also add the keys to `/root/.ssh/authorized_keys` |
| `SUDO_NOPASSWD` | `n` | passwordless sudo (forced when no password is set) |
| `SSH_PASSWORD_AUTH` | `keep` | `disable` turns off SSH password login |
| `ROOT_LOGIN` | `keep` | `key-only` (keys only) or `no` for root SSH login |
| `PVE_ADMIN` | `y` | Proxmox only: add `<user>@pam` as web UI Administrator |

The defaults change nothing that already works. SSH changes go in
`/etc/ssh/sshd_config.d/10-adduser.conf`, are checked with `sshd -t` before restart, and
password login is never disabled when no key was installed.

Proxmox: keep `SSH_PASSWORD_AUTH=keep` until the node has joined the cluster
(`pvecm add` asks for the root password over SSH).

```bash
EXTRA_PUBKEY="ssh-ed25519 AAAA... homelab-admin" bash adduser.sh
```
