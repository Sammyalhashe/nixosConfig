#!/bin/bash
set -e
PLIST="/Library/LaunchDaemons/systems.determinate.nix-daemon.plist"
PROXY="http://proxy.bloomberg.com:81"

/usr/libexec/PlistBuddy -c "Delete :EnvironmentVariables" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:http_proxy string $PROXY" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:https_proxy string $PROXY" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:HTTP_PROXY string $PROXY" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:HTTPS_PROXY string $PROXY" "$PLIST"
launchctl kickstart -k "system/systems.determinate.nix-daemon"
echo "Done. Nix daemon restarted with proxy."
