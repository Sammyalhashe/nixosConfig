{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nixvim-package = inputs.nixvim.packages."${pkgs.stdenv.hostPlatform.system}".default;
  extended-nixvim =
    if config.stylix.enable && config.stylix.targets.nixvim.enable then
      nixvim-package.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-package;
in
{
  home.packages = with pkgs; [
    gh
    extended-nixvim
    fd
    fzf
    git
    ripgrep
    python313Packages.pip
    python313Packages.virtualenvwrapper

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
}
