{ ... }:
{
  imports = [
    # ./desktop.nix
    ./alacritty.nix
    ./direnv.nix
    ./mods.nix
    ./nushell.nix
    ./starship.nix
    ./tmux.nix
    ./wezterm.nix
    ./wsl.nix
    ./yazi.nix
    ./zellij.nix
    ./zsh.nix
  ];

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  programs.neovim.enable = true;
}
