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

Set as environment variables before the command:

| Variable | Default | Effect |
|---|---|---|
| `ROOT_KEYS` | `no` | `yes` also adds the GitHub keys to `/root/.ssh/authorized_keys` |
| `EXTRA_PUBKEY` | empty | one more public key (for example a lab admin key), added for the user and, with `ROOT_KEYS=yes`, for root |
| `DISABLE_PASSWORD_AUTH` | `yes` | `no` keeps SSH password login |

Proxmox: run the script with `DISABLE_PASSWORD_AUTH=no` until the node has joined the cluster
(`pvecm add` asks for the root password over SSH), then run it again with the default.

```bash
ROOT_KEYS=yes DISABLE_PASSWORD_AUTH=no EXTRA_PUBKEY="ssh-ed25519 AAAA... homelab-admin" bash adduser.sh
```
