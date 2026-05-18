{
  config,
  pkgs,
  inputs,
  user,
  homeDir,
  ...
}:
let
  nixvim-package = inputs.nixvim.packages."${pkgs.stdenv.hostPlatform.system}".default;

  nixvim-wsl = nixvim-package.extend { nixvim.wsl = false; };
  extended-nixvim =
    if (config.stylix or { }).enable or false then
      nixvim-wsl.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-wsl;
in
{
  imports = [ ./home-common.nix ];

  home.username = "${user}";
  home.homeDirectory = "${homeDir}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    lazygit

    # neovim
    extended-nixvim

    # terminal utilities
    cargo
    rustc
    gcc
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Stylix theming — darwin stylix propagates the HM module; we just opt in here.
  stylix.enable = true;
  stylix.targets.alacritty.enable = true;
}
