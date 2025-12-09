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

## 2. Bootstrapping the Nodes

Before Colmena can deploy, the Pis must be accessible via SSH and have the decryption key.

### Step 1: Install NixOS
Install NixOS on the Raspberry Pis (e.g., using an SD card image).
*   Ensure the user `root` has your SSH public key in `/root/.ssh/authorized_keys`.
*   Verify you can `ssh root@<pi-ip>` without a password.

### Step 2: Provision the Age Key
Copy your Age private key to the Pi so it can decrypt secrets.

**On your desktop:**
```bash
# Example for pi1
ssh root@11.125.37.99 "mkdir -p /var/lib/sops-nix"
scp ~/.config/sops/age/keys.txt root@11.125.37.99:/var/lib/sops-nix/key.txt
ssh root@11.125.37.99 "chmod 600 /var/lib/sops-nix/key.txt"
```
*Repeat for `pi2`.*

---

## 3. Deployment

Deploy the configurations from your desktop.

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

## Troubleshooting

*   **`colmena: command not found`**: Use `nix run nixpkgs#colmena -- ...` or install it.
*   **"Failed to decrypt"**: Check that `/var/lib/sops-nix/key.txt` exists on the target Pi and that the corresponding public key is in `.sops.yaml`. If you changed `.sops.yaml`, run `sops updatekeys secrets/secrets.yaml`.
*   **PostgreSQL errors**: Nextcloud creates the DB automatically. Check logs: `ssh root@pi2 journalctl -u postgresql`.
