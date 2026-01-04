{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.environments.wsl;
  windowsWeztermPath = "/mnt/c/Users/${cfg.windowsUsername}/.config/wezterm/wezterm.lua";
  weztermConfigPathWsl = "/home/${config.home.username}/.config/wezterm/wezterm.lua";
  windowsAlacrittyPath = "/mnt/c/Users/${cfg.windowsUsername}/AppData/Roaming/alacritty/alacritty.toml";

  # Set the shell configuration to nu for Windows
  alacrittySettings = config.programs.alacritty.settings;
  windowsAlacrittySettings = alacrittySettings // {
    terminal = (alacrittySettings.terminal or {}) // {
      shell = {
        program = "nu";
      };
    };
    window = (alacrittySettings.window or {}) // {
      startup_mode = "Maximized";
      decorations = "None";
    };
  };

  tomlFormat = pkgs.formats.toml {};
  windowsAlacrittyConfigFile = tomlFormat.generate "alacritty-windows.toml" windowsAlacrittySettings;
in
{
  options.environments.wsl = {
    enable = mkEnableOption "Whether to enable WSL environment settings";

    windowsUsername = mkOption {
      type = types.str;
      description = "Your Windows username for placing files in /mnt/c/Users/<username>";
    };
  };

  config = mkIf cfg.enable {
    # home.activation.copyWeztermConfig = hm.dag.entryAfter [ "writeBoundary" ] ''
    #   cp -f ${weztermConfigPathWsl} ${windowsWeztermPath}
    # '';
    home.activation.copyAlacritty = hm.dag.entryAfter [ "writeBoundary" ] ''
      cp -f ${windowsAlacrittyConfigFile} ${windowsAlacrittyPath}
    '';
  };
}
