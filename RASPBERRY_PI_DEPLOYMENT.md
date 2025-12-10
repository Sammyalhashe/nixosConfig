# Raspberry Pi Cluster Deployment Guide

This repository uses **Colmena** to manage and deploy two Raspberry Pi 4 nodes (`pi1`, `pi2`) running NixOS. It uses **SOPS-Nix** for secure secret management.

## Architecture

| Node | IP Address | Role | Services |
| :--- | :--- | :--- | :--- |
| **pi1** | `11.125.37.99` | Network/Privacy | AdGuard Home, WireGuard VPN (via Wg-Easy) |
| **pi2** | `11.125.37.235` | Services/Storage | Gitea, Syncthing, Nextcloud (PostgreSQL) |

Your desktop (`homebase` / `starshipwsl`) is configured to cross-compile these configurations (x86_64 -> aarch64).

---

## Prerequisites

Ensure you have the following installed on your management machine (Desktop):
*   **Nix** (with flakes enabled)
*   **Colmena**: `nix run nixpkgs#colmena -- --help`
*   **SOPS**: `nix run nixpkgs#sops -- --help`
*   **Age**: `nix run nixpkgs#age -- --help`

---

## 1. Secrets Setup (First Time Only)

We use **SOPS** with **Age** encryption to store secrets like VPN passwords and Database passwords.

### Step 1: Generate your Age Identity
If you don't have an age key yet:
```bash
mkdir -p ~/.config/sops/age
nix run nixpkgs#age -- -o ~/.config/sops/age/keys.txt keygen
```
*   **Public Key**: Starts with `age1...`. You will need this for `.sops.yaml`.
*   **Private Key**: Kept in `keys.txt`. **Never commit this.**

### Step 2: Configure `.sops.yaml`
1.  Open `.sops.yaml` in the root of the repo.
2.  Replace the placeholder under `&admin_user` with your **Public Key**.
3.  (Optional) Ideally, generate separate keys for `pi1` and `pi2` (ssh into them, generate key, get public key) and add them to `.sops.yaml` so they can decrypt secrets independently. For bootstrapping, you can reuse one key or copy your admin key (less secure).

### Step 3: Populate Secrets
Create/Edit the secrets file:
```bash
nix run nixpkgs#sops -- secrets/secrets.yaml
```
This opens your editor. Paste the following structure (replacing values):

```yaml
# Environment variables for Wg-Easy (WireGuard Web UI)
wg_easy_env: |
    PASSWORD=my_secure_web_ui_password

# Admin password for Nextcloud
nextcloud_admin_pass: |
    <YOUR_STRONG_PASSWORD_HERE>
```
Save and exit. The file will be encrypted on disk.

---

## 2. Bootstrapping (Scenario A: Manual Install)

Use this method if you have already flashed a NixOS SD card image and the Pi is running, but you need to set up the keys for Colmena deployment.

### Step 1: Install NixOS
Install NixOS on the Raspberry Pis (e.g., using an SD card image).
*   Ensure the user `root` has your SSH public key in `/root/.ssh/authorized_keys`.
*   Verify you can `ssh root@<pi-ip>` without a password.

### Step 2: Provision the Age Key
The Age private key is required for the Pi to decrypt secrets (like VPN passwords) at boot time. Since we cannot store this private key in the public Git repository, it must be copied to the device manually.

**Option A: Helper Script (Recommended)**
This script checks if the key exists on your desktop and securely copies it to the correct location on the Pi with the right permissions.
```bash
# Make script executable first
chmod +x scripts/provision-keys.sh

# Run script
./scripts/provision-keys.sh root@11.125.37.99
```

**Option B: Manual Copy**
If you prefer to see exactly what is happening:
```bash
ssh root@11.125.37.99 "mkdir -p /var/lib/sops-nix"
scp ~/.config/sops/age/keys.txt root@11.125.37.99:/var/lib/sops-nix/key.txt
ssh root@11.125.37.99 "chmod 600 /var/lib/sops-nix/key.txt"
```
*Repeat for `pi2`.*

---

## 3. Deployment

Once keys are provisioned, deploy the configurations from your desktop using Colmena.

```bash
# Deploy to all nodes
nix run nixpkgs#colmena -- apply

# Deploy to a specific node (e.g., pi2)
nix run nixpkgs#colmena -- apply --on pi2
```

*Note: The first deployment might take a while as it cross-compiles packages.*

---

## 4. Service Access

| Service | Node | URL / Port | Notes |
| :--- | :--- | :--- | :--- |
| **AdGuard Home** | pi1 | `http://11.125.37.99:3000` | Setup Wizard on first load |
| **WireGuard UI** | pi1 | `http://11.125.37.99:51821` | **Log in here to create clients & scan QR codes.** |
| **Gitea** | pi2 | `http://11.125.37.235:3000` | Git Service |
| **Syncthing** | pi2 | `http://11.125.37.235:8384` | User: `sammy` |
| **Nextcloud** | pi2 | `http://11.125.37.235` | Admin user: `admin`, Password: (from secrets) |

---

## 5. Connecting a New VPN Client

Since we are using **Wg-Easy**, managing VPN clients does **not** require redeploying NixOS.

1.  Open the WireGuard Web UI: `http://11.125.37.99:51821`.
2.  Log in with the password you defined in `secrets/secrets.yaml` (`wg_easy_env`).
3.  Click **"New Client"**.
4.  Enter a name (e.g., "iPhone", "Laptop").
5.  Click **Create**.
6.  Click the **QR Code icon** to scan it with your phone, or download the `.conf` file for your desktop.

---

## 6. Fresh Install with NixOS-Anywhere (Scenario B: Nuclear Option)

Use this method if you want to **completely wipe the SD card**, re-partition it, and install NixOS from scratch using your configuration. This is useful for disaster recovery or starting fresh without manually flashing an SD card image.

**Prerequisites**:
*   The Pi must be accessible via SSH (from any Linux distro).
*   You must be willing to lose ALL data on the SD card.

**Steps:**

1.  **Enable Partition Management**:
    By default, we disable partition management to prevent accidental data loss. To enable it:
    *   Edit `hosts/pi1/default.nix` (or `pi2`).
    *   Uncomment the line `# ../../common/pi-sd-card.nix`.
    *   *Tip: Remember to comment it out again after installation if you want to be safe.*

2.  **Run the Installation**:
    We use `nixos-anywhere` to drive the installation. We pass the keys via `--extra-files` so they are copied during the install, ensuring the new system boots up ready to decrypt secrets.

    ```bash
    # 1. Create a temporary directory for keys
    mkdir -p /tmp/keys/var/lib/sops-nix

    # 2. Copy your age key into that structure
    cp ~/.config/sops/age/keys.txt /tmp/keys/var/lib/sops-nix/key.txt

    # 3. Run the installer (REPLACE IP ADDRESS)
    nix run github:nix-community/nixos-anywhere -- \
      --extra-files /tmp/keys \
      --flake .#pi1 \
      root@11.125.37.99
    ```

**Important Caveat**:
Standard `nixos-anywhere` installations might wipe the firmware partition needed to boot the Pi. If the system fails to boot after this, you may need to manually mount the SD card on your computer and copy the Raspberry Pi firmware files (`start4.elf`, `fixup4.dat`, etc.) to the first partition (`/boot`).

---

## Troubleshooting

*   **`colmena: command not found`**: Use `nix run nixpkgs#colmena -- ...` or install it.
*   **"Failed to decrypt"**: Check that `/var/lib/sops-nix/key.txt` exists on the target Pi and that the corresponding public key is in `.sops.yaml`. If you changed `.sops.yaml`, run `sops updatekeys secrets/secrets.yaml`.
*   **PostgreSQL errors**: Nextcloud creates the DB automatically. Check logs: `ssh root@pi2 journalctl -u postgresql`.
