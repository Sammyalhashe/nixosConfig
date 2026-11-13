{
  config,
  lib,
  inputs,
  ...
}:
let
  lig = lib.getExe config.programs.lig.package;
in
{
  imports = [ inputs.lig.homeModules.default ];

  programs.lig.enable = true;

  # lig hooks bash through home-manager's bashrc, so home-manager has to own it.
  programs.bash.enable = true;

  # Ryoku materializes its own read-only config.fish, so fish stays out of
  # home-manager and lig loads from conf.d instead of programs.fish.
  xdg.configFile."fish/conf.d/lig.fish".text = ''
    eval (${lig} init fish pre | string collect)
    eval (${lig} init fish post | string collect)
  '';
}
