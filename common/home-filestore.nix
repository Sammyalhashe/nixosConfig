{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nixvim-package = inputs.nixvim.packages."${pkgs.stdenv.hostPlatform.system}".default;
  extended-nixvim =
    if config.stylix.enable then
      nixvim-package.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-package;
in
{
  home.packages = with pkgs; [
    extended-nixvim
    git
    ripgrep
    fd
    fzf
    bat
    gemini-cli

    # minimal charmbracelet
    nur.repos.charmbracelet.gum
    nur.repos.charmbracelet.glow
    nur.repos.charmbracelet.mods

    # system tools
    btop
    htop
    unzip
    zip
    jq
    yq-go

    # networking
    dig
  ];

  systemd.user.services.neovim_server = {
    Unit = {
      Description = "Neovim server to connect to for fast startup";
    };
    Service = {
      ExecStart = "${extended-nixvim}/bin/nvim --listen 127.0.0.1:8888 --headless";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
