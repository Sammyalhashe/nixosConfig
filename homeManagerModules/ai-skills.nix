{ inputs, lib, pkgs, config, ... }:
let
  cfg = config.ai-skills;
in
{
  options.ai-skills = {
    enable = lib.mkEnableOption "Install AI skills and agents from the skills flake";
    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.ai-skills.packages.${pkgs.system}.ai-skills;
      defaultText = lib.literalExpression "inputs.ai-skills.packages.\${pkgs.system}.ai-skills";
      description = "The AI skills derivation to install";
    };

    claude.model = lib.mkOption {
      type = lib.types.str;
      default = "opus[1m]";
      description = "Claude model identifier for settings.json";
    };

    claude.theme = lib.mkOption {
      type = lib.types.str;
      default = "dark-ansi";
      description = "Claude Code theme";
    };

    claude.plugins = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Enabled Claude Code plugins";
    };

    claude.skipDangerousPrompt = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Skip dangerous mode permission prompt";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/skills" = {
      source = "${cfg.package}/claude";
      recursive = true;
    };

    home.file.".gemini/skills" = {
      source = "${cfg.package}/gemini";
      recursive = true;
    };

    home.file.".openai/skills" = {
      source = "${cfg.package}/openai";
      recursive = true;
    };

    home.file.".claude/settings.json" = {
      force = true;
      text = builtins.toJSON {
        model = cfg.claude.model;
        statusLine = {
          type = "command";
          command = "bash \"${cfg.package}/claude/bin/statusline.sh\"";
        };
        enabledPlugins = cfg.claude.plugins;
        skipDangerousModePermissionPrompt = cfg.claude.skipDangerousPrompt;
        theme = cfg.claude.theme;
      };
    };
  };
}
