{ ... }:
{
  imports = [
    # ./desktop.nix
    ./git.nix
    ./jj.nix
    ./ai-skills.nix
    ./alacritty.nix
    ./claude-code.nix
    ./coinbase-cli.nix
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

  programs.neovim.enable = false;

  ai-skills.enable = true;
}
