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
    ../homeManagerModules/base.nix
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
    # Bitcoin wallet; point it at the node on mothership rather than a public
    # server. See modules/crypto/sparrow.nix for the connection options.
    sparrow
    # Timelock-based recovery wallet; same backend choices as Sparrow.
    # See modules/crypto/liana.nix.
    liana
    # Kaspa wallet. Point it at mothership (Remote -> ws://mothership.salh.xyz:17110)
    # rather than letting it sync its own DAG. See modules/crypto/kaspa-ng.nix.
    (import ../pkgs/kaspa-ng.nix { inherit pkgs; })
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  nix.package = pkgs.nix;

  programs.home-manager.enable = true;

}
