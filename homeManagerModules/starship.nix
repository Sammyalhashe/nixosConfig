{ config, pkgs, ... }:

{
  home.packages = [ pkgs.jj-starship ];

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      # Get editor completions based on the config schema
      # "$schema" = "https://starship.rs/config-schema.json";

      # Disable the package module, hiding it from the prompt completely
      package.disabled = true;

      format = ''
        $directory ''${custom.jj}$git_state$git_metrics $character
      '';

      # jj-starship renders both jj and git repos, replacing git_branch,
      # git_commit and git_status (see flake input jj-starship)
      custom.jj = {
        when = "jj-starship detect";
        shell = [ "jj-starship" ];
        format = "$output ";
      };

      git_metrics = {
        disabled = false;
        added_style = "bold green";
        deleted_style = "bold red";
      };

      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[✖](bold red) ";
      };

      directory = {
        disabled = false;
        format = "[ $path](bold red)";
        truncate_to_repo = false;
      };

      git_status.disabled = true;
      git_branch.disabled = true;
    };
  };
}
