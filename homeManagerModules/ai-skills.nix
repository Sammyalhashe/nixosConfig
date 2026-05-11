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
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/plugins/marketplaces/user" = {
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
  };
}
