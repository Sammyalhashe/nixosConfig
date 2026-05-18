{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  user = "sammyalhashemi";
in
{
  imports = [
    inputs.home-manager.darwinModules.default
    ../../common/home-manager-config.nix
  ];

  host.username = user;
  host.homeManagerHostname = "KQ7DV474L1";

  # Determinate Nix manages the nix daemon; disable the nixpkgs-provided one
  nix.enable = false;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    shell = pkgs.nushell;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
  ];

  fonts.packages = with pkgs; [
    monoid
    source-code-pro
  ];

  system.stateVersion = 6;

}
