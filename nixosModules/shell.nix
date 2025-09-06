{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = false;
    enableCompletion = false;

    # This command let's me execute arbitrary binaries downloaded through channels such as mason.
    shellInit = ''
      export NIX_LD=$(nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')
    '';
  };

  # programs.nushell = {
  #   enable = true;
  # };

  users.defaultUserShell = pkgs.nushell;
}
