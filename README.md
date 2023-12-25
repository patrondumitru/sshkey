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
   bash -c "$(wget -qLO - https://github.com/patrondumitru/sshkey/adduser.sh)"

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
