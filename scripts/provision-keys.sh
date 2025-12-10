#!/usr/bin/env bash
set -e

# Usage: ./scripts/provision-keys.sh <target-host> [key-file]
# Example: ./scripts/provision-keys.sh root@11.125.37.99 ~/.config/sops/age/keys.txt

TARGET="$1"
KEY_FILE="${2:-$HOME/.config/sops/age/keys.txt}"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-host> [key-file]"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file $KEY_FILE not found."
    exit 1
fi

echo "Provisioning keys to $TARGET..."

# Ensure directory exists
ssh "$TARGET" "mkdir -p /var/lib/sops-nix"

# Copy key
scp "$KEY_FILE" "$TARGET:/var/lib/sops-nix/key.txt"

# Set permissions
ssh "$TARGET" "chmod 600 /var/lib/sops-nix/key.txt"

echo "Done. Key provisioned to $TARGET."
