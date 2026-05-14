{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      # Get editor completions based on the config schema
      # "$schema" = "https://starship.rs/config-schema.json";

      # Disable the package module, hiding it from the prompt completely
      package.disabled = true;

      format = ''
        $directory $jj$git_commit$git_state$git_status$git_metrics $character
      '';

      custom.jj = {
        # Only run this if we are actually in a JJ repo
        command = "jj log -r @ -T '\"🌀 \" ++ change_id.short() ++ if(bookmarks, \" (\" ++ bookmarks ++ \")\")' --no-graph";
        when = "jj root"; # This is the fastest way to check if we're in a jj repo
        shell = [
          "sh"
          "-c"
        ];
        style = "bold magenta";
        format = "[$output]($style) ";
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

      git_status = {
        format = " ([$all_status$ahead_behind](bold green))";
        staged = "• ";
        modified = "~ ";
        untracked = "+ ";
        deleted = "x ";
      };

      git_branch.disabled = true;
    };
  };
}
