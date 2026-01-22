{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  # Resolve conflicts with other modules (like omarchy-nix) that might try to
  # define style.css via home.file. We only want the xdg.configFile generation
  # from programs.wofi below.
  home.file.".config/wofi/style.css".enable = lib.mkForce false;

  programs.wofi = {
    enable = true;
    settings = {
      mode = "drun";
      allow_images = true;
      width = 500;
      height = 300;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      image_size = 24;
      gtk_dark = true;
      dynamic_lines = true;
    };
    style = lib.mkForce ''
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-weight: bold;
        font-size: 14px;
      }

      window {
        background-color: transparent;
        margin: 0px;
      }

      #outer-box {
        margin: 0px;
        border: 2px solid ${colors.base0E};
        background-color: ${colors.base00};
        border-radius: 24px;
        padding: 10px;
      }

      #input {
        margin: 5px 10px;
        padding: 5px;
        border: none;
        color: ${colors.base05};
        background-color: ${colors.base02};
        border-radius: 12px;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: transparent;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: ${colors.base05};
      }

      #entry {
        border: none;
        border-radius: 12px;
        padding: 5px 10px;
      }

      #entry:selected {
        background-color: ${colors.base0E};
        color: ${colors.base00};
        border-radius: 12px;
        outline: none;
      }

      #entry:selected #text {
        color: ${colors.base00};
      }
    '';
  };
}
