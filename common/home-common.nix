{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Define the package name and version once so they can be reused safely.
  openTerminalPname = "open-terminal";
  openTerminalVersion = "0.1.0"; # <-- update to the actual version you need

  # -------------------------------------------------------------------------
  # The real `open-terminal` package is not available on PyPI (the URL returns
  # 404), which caused the build to fail.  To keep the system buildable we
  # provide a minimal stub package that installs a tiny executable.  This stub
  # can be replaced later with a proper `buildPythonPackage` derivation once the
  # correct source (e.g. a GitHub repository or a different PyPI name) is
  # known.
  # -------------------------------------------------------------------------
  open-terminal = pkgs.stdenv.mkDerivation {
    pname = openTerminalPname;
    version = openTerminalVersion;

    # No source to fetch – the derivation is self‑contained.
    src = null;

    # The build is a no‑op; we only need to create a placeholder executable.
    buildPhase = ''
      echo "Building stub open-terminal package..."
    '';

    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/open-terminal <<'EOF'
#!/usr/bin/env sh
# Stub implementation of the `open-terminal` package.
# Replace this with the real package when a proper source is available.
echo "open-terminal placeholder (version ${openTerminalVersion})"
EOF
      chmod +x $out/bin/open-terminal
    '';

    # Ensure the package appears as a normal executable in $PATH.
    meta = with lib; {
      description = "Stub for the open-terminal Python package (unavailable on PyPI)";
      homepage = "";
      license = licenses.unfree; # placeholder
      maintainers = [];
      platforms = platforms.all;
    };
  };
in
{
  home.packages =
    with pkgs;
    [
      # common applications
      git

      # nur repos
      pkgs.nur.repos.charmbracelet.glow
      pkgs.nur.repos.charmbracelet.mods
      pkgs.nur.repos.charmbracelet.skate
      pkgs.nur.repos.charmbracelet.crush
      pkgs.nur.repos.charmbracelet.pop
      pkgs.nur.repos.charmbracelet.gum

      # terminal utilities
      alacritty
      bat
      cowsay
      delta
      dua
      fd
      fortune
      fzf
      gemini-cli
      gh
      grim
      neofetch
      notejot
      pandoc
      ripgrep
      russ
      slurp
      sops
      starship
      texliveSmall
      tmux
      wl-clipboard
      xclip
      yazi
      zellij
      zoxide

      # fonts
      iosevka

      # add the open-terminal stub package
      open-terminal
    ]
    ++ [
      (import ./scripts/test.nix { inherit pkgs; })
      (import ./scripts/hgrep.nix { inherit pkgs; })
      (import ./scripts/crypto.nix { inherit pkgs; })
      (import ./scripts/tmux-cht.nix { inherit pkgs; })
      (import ./scripts/fzf-man.nix { inherit pkgs; })
      (import ./scripts/system-copy.nix { inherit pkgs; })
    ];

  programs.aider.enable = true;

  systemd.user.services.neovim_server = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Neovim server to connect to for fast startup";
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec $(which nvim) --listen 127.0.0.1:8888 --headless'";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
