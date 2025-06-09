
{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = false;

    # This command let's me execute arbitrary binaries downloaded through channels such as mason.
    initExtra = ''
      export NIX_LD=$(nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')
    '';
  };

  users.defaultUserShell = pkgs.zsh;
}
