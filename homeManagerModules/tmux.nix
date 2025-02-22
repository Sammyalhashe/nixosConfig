{ config, pkgs, ... }:
let
sessionx = pkgs.tmuxPlugins.mkTmuxPlugin
{
    pluginName = "sessionx";
    version = "unstable-2024-09-09";
    src = pkgs.fetchFromGitHub {
        owner = "omerxx";
        repo = "tmux-sessionx";
        rev = "ecc926e7db7761bfbd798cd8f10043e4fb1b83ba";
        sha256 = "sha256-S/1mcmOrNKkzRDwMLGqnLUbvzUxcO1EcMdPwcipRQuE=";
    };
};
in
{
    programs.tmux = {
        enable = true;
        plugins = with pkgs; [
        #     tmuxPlugins.sensible
            {
                plugin = tmuxPlugins.vim-tmux-navigator;
                extraConfig = ''
                    # vim-tmux-navigator
                    # vim-tmux-navigator overrides the <C-l> clear screen, so add a <prefix>+<C-l>
                    # mapping to overcome it :/
                    bind C-l send-keys 'C-l'
                '';
            }
        #     # {
        #     #     plugin = sessionx;
        #     #     extraConfig = ''
        #     #         set -g @sessionx-bind 'o'
        #     #         set -g @sessionx-x-path '~/dotfiles'
        #     #         set -g @sessionx-window-height '85%'
        #     #         set -g @sessionx-window-width '75%'
        #     #         set -g @sessionx-zoxide-mode 'on'
        #     #     '';
        #     # }
        #     {
        #         plugin = tmuxPlugins.tmux-fzf;
        #         extraConfig = ''
        #             set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
        #             set -g @fzf-url-history-limit '2000'
        #         '';
        #     }
        #     {
        #         plugin = tmuxPlugins.resurrect;
        #         extraConfig = ''
        #             set -g @resurrect-save 'S'
        #             set -g @resurrect-restore 'R'
        #         '';
        #     }
        ];
        extraConfig = ''
            # ==========================
            # ===  General settings  ===
            # ==========================

            set -g default-terminal "xterm-256color"
            set -g history-limit 20000
            set -g buffer-limit 20
            set -sg escape-time 0
            set -g display-time 1500
            set -g remain-on-exit off
            set -g repeat-time 301
            setw -g mouse on
            # set -ga terminal-overrides ',*256color*:smcup@:rmcup@'
            setw -g allow-rename off
            setw -g automatic-rename off
            setw -g aggressive-resize on

            set-window-option -g mode-keys vi
            bind-key -T copy-mode-vi v send -X begin-selection
            bind-key -T copy-mode-vi V send -X select-line
            bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

            bind-key m set-option mouse \; display-message "mouse #{?mouse,on,off}"

            set-option -ga terminal-overrides ",xterm-256color:Tc"

            # Change prefix key to C-a, easier to type, same to "screen"
            unbind C-b
            set -g prefix C-a

            # Start index of window/pane with 1, because we're humans, not computers
            set -g base-index 1
            setw -g pane-base-index 1

            # Set parent terminal title to reflect current window in tmux session 
            set -g set-titles on
            set -g set-titles-string "#I:#W"

            # Rename session and window
            bind r command-prompt -I "#{window_name}" "rename-window '%%'"
            bind R command-prompt -I "#{session_name}" "rename-session '%%'"

            # Split panes
            bind | split-window -h -c "#{pane_current_path}"
            bind _ split-window -v -c "#{pane_current_path}"

            # Move status bar to the top
            set-option -g status-position top

            # new window and retain cwd
            bind c new-window -c "#{pane_current_path}"

            # Kill pane/window/session shortcuts
            bind x kill-pane
            bind X kill-window

            # maximize pane
            bind + resize-pane -Z

            # resize panes
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5

            # Select pane and windows
            bind -r Tab last-window   # cycle thru MRU tabs

            # ============================
            # ===       Plugins        ===
            # ============================

            set -g @plugin 'tmux-plugins/tpm'

            # Set of defaults
            # set -g @plugin 'tmux-plugins/tmux-sensible'

            # Miscellaneous tools
            set -g @plugin 'sainnhe/tmux-fzf'
            set -g @plugin 'jaclu/tmux-power-zoom'
            set -g @plugin 'wfxr/tmux-fzf-url'

            # Navigation
            # set -g @plugin 'christoomey/vim-tmux-navigator'

            # Session Management
            set -g @plugin 'tmux-plugins/tmux-resurrect'

            # Statusline
            set -g @plugin 'aaronpowell/tmux-weather'
            set -g @plugin 'tmux-plugins/tmux-battery'

            set -g @plugin 'tmux-plugins/tmux-yank'
            set -g @plugin 'tmux-plugins/tmux-resurrect'
            set -g @plugin 'tmux-plugins/tmux-continuum'
            set -g @plugin 'fcsonline/tmux-thumbs'
            set -g @plugin 'catppuccin/tmux'
            set -g @plugin 'omerxx/tmux-sessionx'

            # ===================================
            # ===       Plugin Configs        ===
            # ===================================

            # Resurrect
            set -g @resurrect-save 'S'
            set -g @resurrect-restore 'R'

            # Weather
            set -g @forecast-format '%C'+'|'+'Dusk:'+'%d'
            set -g @forecast-location NewYork

            # tmux-power-zoom
            # set -g @power_zoom_trigger '+'

            # vim-tmux-navigator
            # vim-tmux-navigator overrides the <C-l> clear screen, so add a <prefix>+<C-l>
            # mapping to overcome it :/
            bind C-l send-keys 'C-l'

            set -g pane-active-border-style 'fg=magenta,bg=default'
            set -g pane-border-style 'fg=brightblack,bg=default'

            set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
            set -g @fzf-url-history-limit '2000'

            unbind-key 'o'
            set -g @sessionx-legacy-fzf-support 'on'
            set -g @sessionx-bind 'o'
            set -g @sessionx-x-path '~/.dotfiles'
            set -g @sessionx-window-height '85%'
            set -g @sessionx-window-width '75%'
            # set -g @sessionx-zoxide-mode 'on'
            set -g @sessionx-window-mode 'on'

            set -g @continuum-restore 'on'
            set -g @resurrect-strategy-nvim 'session'


            set -g @catppuccin_flavour $catpuccin_color # or frappe, macchiato, mocha

            # set -g @catppuccin_window_left_separator " █"
            set -g @catppuccin_window_left_separator " █"
            set -g @catppuccin_window_right_separator "█ "
            set -g @catppuccin_window_number_position "left"
            set -g @catppuccin_window_middle_separator " | "

            set -g @catppuccin_window_default_fill "none"

            set -g @catppuccin_window_current_fill "all"

            set -g @catppuccin_status_modules_right "application session user host date_time"
            set -g @catppuccin_status_left_separator "█"
            set -g @catppuccin_status_right_separator "█"

            set -g @catppuccin_date_time_text "%Y-%m-%d %H:%M:%S"

            # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
            run '${config.xdg.configHome}/tmux/plugins/tpm/tpm'

            # my own bindings
            bind i new-window ~/.dotfiles/self_scripts/choose_shell


            # We want to have single prefix key "C-a", usable both for local and remote session
            # we don't want to "C-a" + "a" approach either
            # Idea is to turn off all key bindings and prefix handling on local session,
            # so that all keystrokes are passed to inner/remote session

            # see: toggle on/off all keybindings · Issue #237 · tmux/tmux - https://github.com/tmux/tmux/issues/237

            # Also, change some visual styles when window keys are off
            color_status_text=default
            color_window_off_status_bg=default
            color_window_off_status_current_bg=default
            color_dark=default
            bind -T root F12  \
                set prefix None \;\
                set key-table off \;\
                set status-style "fg=$color_status_text,bg=$color_window_off_status_bg" \;\
                set window-status-current-format "#[fg=$color_window_off_status_bg,bg=$color_window_off_status_current_bg]$separator_powerline_right#[default] #I:#W# #[fg=$color_window_off_status_current_bg,bg=$color_window_off_status_bg]$separator_powerline_right#[default]" \;\
                set window-status-current-style "fg=$color_dark,bold,bg=$color_window_off_status_current_bg" \;\
                if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
                refresh-client -S \;\

            bind -T off F12 \
              set -u prefix \;\
              set -u key-table \;\
              set -u status-style \;\
              set -u window-status-current-style \;\
              set -u window-status-current-format \;\
              refresh-client -S

           # see https://github.com/nix-community/home-manager/issues/5952
           set -gu default-command
           set -g default-shell "$SHELL"
        '';
    };
}
