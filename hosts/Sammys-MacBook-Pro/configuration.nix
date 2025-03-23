{ pkgs, ... }:
let user = "sammyalhashemi";
in
{
  imports =
    [
      inputs.home-manager.nixosModules.default
      (
        import ./home-manager.nix (
            { inherit inputs user; }
        )
      )
    ];

  # enable flakes
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # auto upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # enable garbage collection
  nix.gc.automatic = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.${user} = {
  #   isNormalUser = true;
  #   description = "Sammy Al Hashemi";
  #   extraGroups = [ "networkmanager" "wheel" ];
  #   packages = with pkgs; [];
  # };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim
  ];

  # xdg env variables
  # environment.sessionVariables = {
  #   XDG_CONFIG_HOME = "$HOME/.config";
  #   XDG_DATA_HOME   = "$HOME/var/lib";
  #   XDG_CACHE_HOME  = "$HOME/var/cache";
  # };

  fonts.packages = with pkgs; [
      monoid
      source-code-pro
  ];

  # List services that you want to enable:

  system.hostPlatform = "x86_64-darwin";
  system.stateVersion = 6;

}
