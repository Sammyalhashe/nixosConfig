{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  user = "salhashemi2";
in
{
  imports = [
    inputs.home-manager.darwinModules.default
    ../../common/home-manager-config.nix
  ];

  host.username = user;
  host.homeManagerHostname = "KQ7DV474L1";
  system.primaryUser = user;

  # Determinate Nix manages the nix daemon; disable the nixpkgs-provided one
  nix.enable = false;

  # Inject corporate proxy env vars, SSL cert, and nix settings into the Determinate Nix daemon
  system.activationScripts.postActivation.text = ''
    PLIST="/Library/LaunchDaemons/systems.determinate.nix-daemon.plist"
    if [ -f "$PLIST" ]; then
      /usr/libexec/PlistBuddy -c "Delete :EnvironmentVariables" "$PLIST" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:http_proxy string http://proxy.bloomberg.com:81" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:https_proxy string http://proxy.bloomberg.com:81" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:HTTP_PROXY string http://proxy.bloomberg.com:81" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:HTTPS_PROXY string http://proxy.bloomberg.com:81" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:NIX_SSL_CERT_FILE string /etc/ssl/certs/ca-certificates.crt" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:GIT_SSL_CAINFO string /etc/ssl/certs/ca-certificates.crt" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:no_proxy string 127.0.0.1,127.0.0.0/8,localhost,.dev.bloomberg.com,.dev.query.bms.bloomberg.com,.dx.bloomberg.com,.inf.bloomberg.com,.stg.bloomberg.com,.bcs.bloomberg.com,.bpv.bloomberg.com,.blpprofessional.com,.sec.infra.bloomberg,bssodev.bloomberg.com,seshttp.bdns.bloomberg.com,bas-web-dev.bdns.bloomberg.com,bashd.bdns.bloomberg.com,basvdp.bdns.bloomberg.com,.bcos.prod-util.query.bms.bloomberg.com,beg.alpha.bloomberg.com,beg.beta.bloomberg.com,beg.prod.bloomberg.com,beg-dx.prod.bloomberg.com" "$PLIST"
      /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:NO_PROXY string 127.0.0.1,127.0.0.0/8,localhost,.dev.bloomberg.com,.dev.query.bms.bloomberg.com,.dx.bloomberg.com,.inf.bloomberg.com,.stg.bloomberg.com,.bcs.bloomberg.com,.bpv.bloomberg.com,.blpprofessional.com,.sec.infra.bloomberg,bssodev.bloomberg.com,seshttp.bdns.bloomberg.com,bas-web-dev.bdns.bloomberg.com,bashd.bdns.bloomberg.com,basvdp.bdns.bloomberg.com,.bcos.prod-util.query.bms.bloomberg.com,beg.alpha.bloomberg.com,beg.beta.bloomberg.com,beg.prod.bloomberg.com,beg-dx.prod.bloomberg.com" "$PLIST"
    fi

    # Append trusted-users to Determinate Nix's custom config
    CUSTOM="/etc/nix/nix.custom.conf"
    if [ -f "$CUSTOM" ]; then
      grep -q 'trusted-users' "$CUSTOM" || echo 'trusted-users = root ${user}' >> "$CUSTOM"
    fi

    # Append Bloomberg CA to Determinate Nix's SSL cert bundle (ssl-cert-file in
    # nix.conf points here and overrides nix.custom.conf, so we must patch this file)
    NIXCERT="/etc/nix/macos-keychain.crt"
    BBCA="${./certs/bloomberg-ca.pem}"
    if [ -f "$NIXCERT" ] && [ -f "$BBCA" ] && ! grep -q "Bloomberg" "$NIXCERT"; then
      {
        echo ""
        echo "# Bloomberg Corporate CA"
        cat "$BBCA"
      } >> "$NIXCERT"
    fi

    # Add Bloomberg CA to macOS System Keychain so Homebrew (and all macOS apps) trust it
    if ! security find-certificate -c "Bloomberg" /Library/Keychains/System.keychain >/dev/null 2>&1; then
      security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$BBCA"
    fi

    # Note: kickstart -k restarts the daemon but doesn't reload env vars from the plist.
    # A full bootout/bootstrap is needed for env var changes, but can't be done during
    # activation (daemon is in use). Env var changes take effect on reboot, or manually:
    #   sudo launchctl bootout system/systems.determinate.nix-daemon
    #   sudo launchctl bootstrap system /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
    launchctl kickstart -k system/systems.determinate.nix-daemon 2>/dev/null || true
  '';

  # Define a user account. Don't forget to set a password with 'passwd'.
  environment.shells = [ pkgs.nushell ];

  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    shell = pkgs.nushell;
  };

  # Corporate proxy — system-wide env vars (used by activation scripts, homebrew, etc.)
  environment.variables = {
    http_proxy = "http://proxy.bloomberg.com:81";
    https_proxy = "http://proxy.bloomberg.com:81";
    HTTP_PROXY = "http://proxy.bloomberg.com:81";
    HTTPS_PROXY = "http://proxy.bloomberg.com:81";
    HOMEBREW_CA_CERTIFICATES = "/etc/ssl/certs/ca-certificates.crt";
    no_proxy = "127.0.0.1,127.0.0.0/8,localhost,.dev.bloomberg.com,.dev.query.bms.bloomberg.com,.dx.bloomberg.com,.inf.bloomberg.com,.stg.bloomberg.com,.bcs.bloomberg.com,.bpv.bloomberg.com,.blpprofessional.com,.sec.infra.bloomberg,bssodev.bloomberg.com,seshttp.bdns.bloomberg.com,bas-web-dev.bdns.bloomberg.com,bashd.bdns.bloomberg.com,basvdp.bdns.bloomberg.com,.bcos.prod-util.query.bms.bloomberg.com,beg.alpha.bloomberg.com,beg.beta.bloomberg.com,beg.prod.bloomberg.com,beg-dx.prod.bloomberg.com";
    NO_PROXY = "127.0.0.1,127.0.0.0/8,localhost,.dev.bloomberg.com,.dev.query.bms.bloomberg.com,.dx.bloomberg.com,.inf.bloomberg.com,.stg.bloomberg.com,.bcs.bloomberg.com,.bpv.bloomberg.com,.blpprofessional.com,.sec.infra.bloomberg,bssodev.bloomberg.com,seshttp.bdns.bloomberg.com,bas-web-dev.bdns.bloomberg.com,bashd.bdns.bloomberg.com,basvdp.bdns.bloomberg.com,.bcos.prod-util.query.bms.bloomberg.com,beg.alpha.bloomberg.com,beg.beta.bloomberg.com,beg.prod.bloomberg.com,beg-dx.prod.bloomberg.com";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    alacritty
    firefox
    aerospace
  ];

  fonts.packages = with pkgs; [
    monoid
    source-code-pro
    maple-mono.NF
  ];

  # Homebrew casks managed by nix-darwin (for macOS-native apps not in nixpkgs)
  homebrew = {
    enable = true;
    casks = [ "ghostty" "cloudflare-warp" ];
    onActivation.cleanup = "none";
  };

  # sops secrets
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.bb_pub_key = { };

  # Bloomberg corporate CA certificates for HTTPS inspection proxy
  security.pki.certificateFiles = [ ./certs/bloomberg-ca.pem ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.stateVersion = 6;

}
