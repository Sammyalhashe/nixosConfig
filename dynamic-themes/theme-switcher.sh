#!/usr/bin/env bash

set -euo pipefail

FLAKE_PATH="/home/salhashemi2/nixosConfig" # Assuming the flake is in the current directory

THEME="$1"
if [[ -z "$THEME" ]]; then
    echo "Usage: $0 <theme-name>"
    echo "Available themes: dark, light" # Update with your theme names
    exit 1
fi

# Resolve the Nix store path for the chosen theme's configurations
THEME_CONFIG_PATH=$(nix build --no-link --print-out-paths "${FLAKE_PATH}#packages.$(nix-instantiate --eval -E 'builtins.currentSystem' --json | tr -d '"').${THEME}ThemeConfigs")

if [[ -z "$THEME_CONFIG_PATH" ]]; then
    echo "Error: Could not find theme configuration for '$THEME'."
    exit 1
fi

echo "Activating theme: $THEME from $THEME_CONFIG_PATH"

# --- 1. Clean up previous theme artifacts (IMPORTANT) ---
# Remove old symlinks/directories to ensure a clean switch
rm -rf "$HOME/.themes/adw-gtk3"
rm -rf "$HOME/.themes/adw-gtk3-dark"
rm -rf "$HOME/.icons/hicolor" # Clean up specific icon cache if necessary
rm -rf "$HOME/.local/share/color-schemes/*" # Clean up previous color schemes
rm -rf "$HOME/.local/share/plasma/look-and-feel/stylix" # Clean up previous plasma look and feel

# --- 2. Create new symlinks based on generated theme configuration ---

# GTK Themes
ln -sf "${THEME_CONFIG_PATH}/share/themes/adw-gtk3" "$HOME/.themes/adw-gtk3"
ln -sf "${THEME_CONFIG_PATH}/share/themes/adw-gtk3-dark" "$HOME/.themes/adw-gtk3-dark"

# Icons
ln -sf "${THEME_CONFIG_PATH}/share/icons/hicolor" "$HOME/.icons/hicolor"

# Color Schemes
mkdir -p "$HOME/.local/share/color-schemes"
cp "${THEME_CONFIG_PATH}/share/color-schemes/"* "$HOME/.local/share/color-schemes/" # Copy all color schemes

# Plasma Look and Feel
mkdir -p "$HOME/.local/share/plasma/look-and-feel"
ln -sf "${THEME_CONFIG_PATH}/share/plasma/look-and-feel/stylix" "$HOME/.local/share/plasma/look-and-feel/stylix"

# --- 3. Apply theme settings using command-line tools ---

# GTK Theme (assuming Adw-gtk3 variants are used)
if [ "$THEME" == "dark" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "Adw-gtk3-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" # For libadwaita/GTK4 apps
elif [ "$THEME" == "light" ]; then
    gsettings set org.gnome.desktop.interface gtk-theme "Adw-gtk3"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" # For libadwaita/GTK4 apps
fi
# Optional: Set icon theme if Stylix manages a specific one
# gsettings set org.gnome.desktop.interface icon-theme "hicolor" # Assuming hicolor is the generated icon theme

# Qt (Kvantum)
# Stylix usually sets QT_QPA_PLATFORMTHEME in home-manager activation
# For runtime switching, we might need to export it and possibly restart applications
export QT_QPA_PLATFORMTHEME="qt5ct" # Or qt6ct depending on setup
# Optional: If Kvantum theme is also generated, set it here.
# For example, `kvantummanager --set KvAdwaitaDark`

# Xresources - Skipped for now, as not directly generated statically by Stylix for extraction
# Alacritty - Skipped for now, as not directly generated statically by Stylix for extraction

echo "Theme '$THEME' applied. You may need to restart some applications (e.g., Alacritty, terminal emulators) for full effect."
echo "For Qt applications, you might need to ensure QT_QPA_PLATFORMTHEME is set in your session."