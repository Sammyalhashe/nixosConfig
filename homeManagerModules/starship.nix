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
              $directory $git_branch$git_commit$git_state$git_status$git_metrics $character
            '';

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
        
            git_branch = {
                format = " [ $branch](bold blue)";
            };
        };
    };
}
