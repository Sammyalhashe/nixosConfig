{ ... }:
{
  imports = [
    # ./desktop.nix
    ./git.nix
    ./jj.nix
    ./lig.nix
    ./ai-skills.nix
    ./alacritty.nix
    ./claude-code.nix
    ./codex.nix
    ./coinbase-cli.nix
    ./direnv.nix
    ./fish.nix
    ./mods.nix
    ./nushell.nix
    ./pi.nix
    ./rbw.nix
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

  # Fish is the login shell for now; turn off to fall back to nushell.
  shells.fish.enable = true;
}
