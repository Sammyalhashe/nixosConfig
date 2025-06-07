{ pkgs, inputs, ... }:
let user = "sammyalhashemi";
in
let homeDir = "/Users";
in
let hostname = "Sammys-MacBook-Pro";
in
{
  imports =
    [
      inputs.home-manager.darwinModules.default
      (
        import ../../common/home-manager.nix (
            { inherit inputs user homeDir hostname; }
        )
      )
    ];

  # enable flakes
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # enable garbage collection
  nix.gc.automatic = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    # isNormalUser = true;
    # description = "Sammy Al Hashemi";
    # extraGroups = [ "networkmanager" "wheel" ];
    # packages = with pkgs; [];
    name = "${user}";
    home = "/Users/${user}";
  };

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

  system.stateVersion = 6;

}
