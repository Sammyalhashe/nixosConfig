{ config, pkgs, ... }:
let
  sessionx = pkgs.tmuxPlugins.mkTmuxPlugin {
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

       # Configure Tmux
       set -g status-position top
       set -g status-style "bg=#{@thm_bg}"
       set -g status-justify "absolute-centre"

       # pane border look and feel
       setw -g pane-border-status top
       setw -g pane-border-format ""
       setw -g pane-active-border-style "bg=#{@thm_bg},fg=#{@thm_overlay_0}"
       setw -g pane-border-style "bg=#{@thm_bg},fg=#{@thm_surface_0}"
       setw -g pane-border-lines single

       # window look and feel
       set -wg automatic-rename on
       set -g automatic-rename-format "Window"

       set -g window-status-format " #I#{?#{!=:#{window_name},Window},: #W,} "
       set -g window-status-style "bg=#{@thm_bg},fg=#{@thm_rosewater}"
       set -g window-status-last-style "bg=#{@thm_bg},fg=#{@thm_peach}"
       set -g window-status-activity-style "bg=#{@thm_red},fg=#{@thm_bg}"
       set -g window-status-bell-style "bg=#{@thm_red},fg=#{@thm_bg},bold"
       set -gF window-status-separator "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}]│"

       set -g window-status-current-format " #I#{?#{!=:#{window_name},Window},: #W,} "
       set -g window-status-current-style "bg=#{@thm_peach},fg=#{@thm_bg},bold"

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
       set -g @plugin 'omerxx/tmux-sessionx'
       set -g @plugin 'tmux-plugins/tmux-online-status'
       set -g @plugin 'tmux-plugins/tmux-battery'
       set -g @plugin 'catppuccin/tmux'


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

       # Configure Catppuccin
       set -g @catppuccin_flavor "macchiato"
       set -g @catppuccin_status_background "none"
       set -g @catppuccin_window_status_style "none"
       set -g @catppuccin_pane_status_enabled "off"
       set -g @catppuccin_pane_border_status "off"

       # Configure Online
       set -g @online_icon "ok"
       set -g @offline_icon "nok"

       # status left look and feel
       set -g status-left-length 100
       set -g status-left ""
       set -ga status-left "#{?client_prefix,#{#[bg=#{@thm_red},fg=#{@thm_bg},bold]  #S },#{#[bg=#{@thm_bg},fg=#{@thm_green}]  #S }}"
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]│"
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_maroon}]  #{pane_current_command} "
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]│"
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_blue}]  #{=/-32/...:#{s|$USER|~|:#{b:pane_current_path}}} "
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]#{?window_zoomed_flag,│,}"
       set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_yellow}]#{?window_zoomed_flag,  zoom ,}"

       # status right look and feel
       set -g status-right-length 100
       set -g status-right ""
       set -ga status-right "#{?#{e|>=:10,#{battery_percentage}},#{#[bg=#{@thm_red},fg=#{@thm_bg}]},#{#[bg=#{@thm_bg},fg=#{@thm_pink}]}} #{battery_icon} #{battery_percentage} "
       set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}, none]│"
       set -ga status-right "#[bg=#{@thm_bg}]#{?#{==:#{online_status},ok},#[fg=#{@thm_mauve}] 󰖩 on ,#[fg=#{@thm_red},bold]#[reverse] 󰖪 off }"
       set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}, none]│"
       set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_blue}] 󰭦 %Y-%m-%d 󰅐 %H:%M "

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
      set -g default-shell "$env.SHELL"
    '';
  };
}
