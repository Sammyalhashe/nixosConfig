{
  pkgs,
  user,
  inputs,
  config,
  homeDir,
  ...
}:
let
  nixvim-package = inputs.nixvim.packages."${pkgs.stdenv.hostPlatform.system}".default;
  nixvim-wsl = nixvim-package.extend {
    nixvim.wsl = false;
    nixvim.dark = false;
    nixvim.themeWatcher = false;
  };
  extended-nixvim =
    if (config.stylix or { }).enable or false then
      nixvim-wsl.extend config.stylix.targets.nixvim.exportedModule
    else
      nixvim-wsl;
in
{
  imports = [
    ./home-common.nix
    ../homeManagerModules/firefox.nix
  ];

  home.username = "${user}";
  home.homeDirectory = "${homeDir}";

  home.stateVersion = "26.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    onlyoffice-desktopeditors
    cloudflare-warp
    extended-nixvim
    ghostty
    discord
    steam
  ];
  

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.kdePackages.plasma-browser-integration
    ];
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default = {
      name = "default";
      isDefault = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        sponsorblock
        darkreader
        metamask
      ];
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  nix.package = pkgs.nix;

  programs.home-manager.enable = true;

}
