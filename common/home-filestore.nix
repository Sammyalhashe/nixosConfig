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
