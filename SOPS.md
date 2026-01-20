# Secret Management with Sops-Nix

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets securely. Secrets are encrypted using age keys derived from SSH host keys and a personal admin key.

## Setup

### 1. Prerequisites

- **sops**: The tool used to view and edit encrypted files.
- **age**: The encryption tool used by sops.
- **ssh-to-age**: Tool to convert SSH keys to age keys (useful for admin key generation).

These are available in the dev shell:
```bash
nix develop
```

### 2. Encryption Logic

We use a "key groups" strategy in `.sops.yaml`.
- **Admin Key:** A personal age key that can decrypt *everything*.
- **Host Keys:** Each host has its own SSH key. We configure sops to encrypt secrets such that *either* the admin key *or* the specific host's key can decrypt them.

## Admin Key Setup

You need a personal age key to manage secrets.

1.  **Generate Key:**
    ```bash
    mkdir -p ~/.config/sops/age
    age-keygen -o ~/.config/sops/age/keys.txt
    ```
2.  **Get Public Key:**
    The public key (starts with `age1...`) is in the `keys.txt` file.
3.  **Register Admin Key:**
    Add this public key to the `.sops.yaml` file under `key_groups` -> `age`.

## What are Age Keys?

[Age](https://github.com/FiloSottile/age) is a modern, simple, and secure file encryption tool. Unlike GPG, it is designed to be easy to use and automate.

In this setup, we use two types of Age identities:
1.  **Personal Admin Key:** A dedicated keypair (stored in `~/.config/sops/age/keys.txt`) that belongs to **you**. It allows you to encrypt and decrypt secrets on any machine where you have this key.
2.  **Derived Host Keys:** Instead of managing separate key files for every server, we convert the server's existing **SSH Host Key** (its identity) into an Age key. This means the server can decrypt secrets using its SSH private key, without needing a separate key file managed manually.

## Host Setup

This config derives age keys from the host's SSH ED25519 key.

1.  **Get Host Public Key:**
    Run this on the target machine (or SSH into it):
    ```bash
    # If this file doesn't exist (common on WSL), generate it first:
    # sudo ssh-keygen -A
    cat /etc/ssh/ssh_host_ed25519_key.pub
    ```
2.  **Convert to Age:**
    Sops needs the key in `age` format. Convert it using `ssh-to-age`:
    ```bash
    echo "ssh-ed25519 AAA..." | ssh-to-age
    ```
3.  **Register Host Key:**
    Add the resulting `age1...` key to `.sops.yaml` in the `keys` section (use a YAML anchor like `&hostname`) and add it to the `creation_rules` -> `key_groups` -> `age` list.
4.  **Update Secrets:**
    Re-encrypt the secrets file so the new host can decrypt it:
    ```bash
    sops updatekeys secrets.yaml
    ```

## Managing Secrets

### Editing Secrets
To edit the secrets file, simply run:
```bash
sops secrets.yaml
```
This opens the file in your `$EDITOR`. When you save and exit, sops automatically re-encrypts the file.

### Rotating Keys
If a host's SSH key changes or you rotate your admin key:
1.  Update the relevant key in `.sops.yaml`.
2.  Run `sops updatekeys secrets.yaml`.

## Troubleshooting

- **"Failed to decrypt" on host:**
    - Check if the host's public SSH key in `.sops.yaml` matches `/etc/ssh/ssh_host_ed25519_key.pub`.
    - Ensure `sops updatekeys secrets.yaml` was run after adding the host.
    - Verify that `sops.age.sshKeyPaths` is correctly set in the host's NixOS config.

- **"Failed to decrypt" on workstation:**
    - Ensure your personal private key is at `~/.config/sops/age/keys.txt` (or pointed to by `SOPS_AGE_KEY_FILE`).
    - Ensure your public key is in `.sops.yaml`.
