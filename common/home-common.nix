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

  # Derivation for the `open-terminal` Python package, which is not available in
  # the default Nixpkgs collection.
  open-terminal = pkgs.python3Packages.buildPythonPackage {
    pname = openTerminalPname;
    version = openTerminalVersion;
    src = pkgs.fetchPypi {
      pname = openTerminalPname;
      version = openTerminalVersion;
      # Use a fake hash so that the first build will report the correct hash.
      # After the first build you can replace `lib.fakeSha256` with the real hash.
      sha256 = lib.fakeSha256;
    };
    # The package does not provide a pyproject.toml, so we need to tell Nix
    # which build system to use.  Using the classic setuptools format works.
    format = "setuptools";
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

      # add the open-terminal Python package
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
