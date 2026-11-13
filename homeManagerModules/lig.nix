{ inputs, ... }:
{
  imports = [ inputs.lig.homeModules.default ];

  programs.lig.enable = true;

  # lig hooks bash through home-manager's bashrc, so home-manager has to own it.
  programs.bash.enable = true;
}
