{
  pkgs,
  inputs,
  config,
  ...
}:
let
  extended-nixvim = import ../../homeManagerModules/lib/nixvim.nix {
    inherit pkgs inputs config;
  } { };
in
{
  imports = [
    ./home-modules.nix
    ../../homeManagerModules/hunk.nix
  ];

  home.packages = with pkgs; [
    gh
    jujutsu
    extended-nixvim
    fd
    fzf
    git
    ripgrep
    python313Packages.pip
    python313Packages.virtualenvwrapper

    # nix stuff
    nix-init
    nurl

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
