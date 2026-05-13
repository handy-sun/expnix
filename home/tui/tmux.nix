{
  config,
  pkgs,
  ...
}:

let
  tmuxConfig = "${config.xdg.configHome}/tmux/tmux.conf";
in

{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    terminal = "xterm-256color";
    baseIndex = 1;
    escapeTime = 50;
    historyLimit = 2000;
    mouse = true;
    focusEvents = true;
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = yank;
        extraConfig = ''
          set -g @yank_action 'copy-pipe'
          set -g @yank_with_mouse on
        '';
      }
      {
        plugin = copycat;
        extraConfig = ''
          set -g @copycat_search '/'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-dir '${config.xdg.dataHome}/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-save-interval '15'
          set -g @continuum-restore 'off'
          set -g @continuum-boot 'off'
        '';
      }
      open
      {
        plugin = tmux-which-key;
        extraConfig = ''
          set -g @tmux-which-key-xdg-enable true
          set -g @tmux-which-key-disable-autobuild true
          set -g @wk_cfg_key_prefix_table "Space"
        '';
      }
      sidebar
      {
        plugin = mode-indicator;
        extraConfig = ''
          set -g @mode_indicator_prefix_prompt ' WAIT '
          set -g @mode_indicator_copy_prompt ' COPY '
          set -g @mode_indicator_sync_prompt ' SYNC '
          set -g @mode_indicator_empty_prompt ' TMUX '
          set -g @mode_indicator_prefix_mode_style 'bg=#83a598,fg=#1d2021'
          set -g @mode_indicator_copy_mode_style 'bg=#ffa500,fg=#1d2021'
          set -g @mode_indicator_sync_mode_style 'bg=#b8bb26,fg=#1d2021'
          set -g @mode_indicator_empty_mode_style 'bg=#3f3c36,fg=#b1b1b1'
        '';
      }
    ];

    extraConfig = ''
      set -g prefix2 C-t
      bind-key C-t send-prefix -2

      setw -g xterm-keys on

      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key h select-pane -L
      bind-key l select-pane -R

      bind -n C-M-h select-pane -L
      bind -n C-M-j select-pane -D
      bind -n C-M-k select-pane -U
      bind -n C-M-l select-pane -R
      bind -n C-M-n next-window
      bind -n C-M-p previous-window

      bind r source-file ${tmuxConfig}

      bind s split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"

      bind m command-prompt -p "join pane to window:" "join-pane -t ':%%'"
      bind M set -g mouse \; display "Mouse #{?mouse,ON,OFF}!"

      set -g status on
      set -g status-style 'bg=#1d2021,fg=#b1b1b1'
      set -g status-interval 5
      set -g status-left-length 40
      set -g status-right-length 80
      set -g status-justify left
      set -g status-left "#[bg=#83a598,fg=#1d2021,bold] #S "
      set -g status-right "#[bg=#3f3c36,fg=#b1b1b1] #{user}@#H #[bg=#ffa500,fg=#1d2021] %H:%M #[bg=#1d2021]#{tmux_mode_indicator}"
      set -g message-style 'bg=#ffa500,fg=#1d2021'
      set -g message-command-style 'bg=#83a598,fg=#1d2021'
      set -g mode-style 'bg=#ffa500,fg=#1d2021'

      setw -g pane-border-status top
      setw -g pane-border-format '#{pane_index} #{pane_current_command} #{b:pane_current_path}'
      setw -g pane-border-style 'fg=#3f3c36'
      setw -g pane-active-border-style 'fg=#83a598'

      set -g set-titles on
      set -g set-titles-string '#(whoami)@#h :: [#S]'

      setw -g automatic-rename on
      setw -g automatic-rename-format '#{pane_current_command}:#{b:pane_current_path}'

      setw -g window-status-separator ' '
      setw -g window-status-format '#[bg=#1d2021,fg=#928374]#{window_index} #[fg=#928374]#W'
      setw -g window-status-current-format '#[bg=#3f3c36,fg=#b1b1b1,bold]#{window_index} #[fg=#83a598]#W'
      setw -g window-status-activity-style 'fg=#ffa500,bg=#1d2021'
      setw -g window-status-bell-style 'fg=#ffa500,bg=#1d2021'

      set -g update-environment "SSH_AUTH_SOCK"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g allow-passthrough on

      bind-key Space show-wk-menu-root
    '';
  };
}
