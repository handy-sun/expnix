{
  config,
  lib,
  pkgs,
  ...
}:

let
  tmuxConfig = "${config.xdg.configHome}/tmux/tmux.conf";
  tmuxBin = lib.getExe pkgs.tmux;
  resurrectSave = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh";
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    terminal = "xterm-256color";
    baseIndex = 1;
    escapeTime = 50;
    historyLimit = 10000;
    mouse = true;
    focusEvents = true;
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = yank;
        extraConfig = ''
          set -g @yank_action 'copy-pipe-and-cancel'
          set -g @yank_with_mouse off
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
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'
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
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "basic"
          set -g @catppuccin_status_connect_separator "yes"
          set -g @catppuccin_cpu_icon "CPU "
          set -g @catppuccin_ram_icon "RAM "
          set -g @catppuccin_date_time_text " %H:%M"
        '';
      }
      {
        plugin = cpu;
        extraConfig = ''
          set -g status-left-length 100
          set -g status-right-length 120
          set -g status-left "#{E:@catppuccin_status_session}"
          set -g status-right "#{E:@catppuccin_status_user}"
          set -ag status-right "#{E:@catppuccin_status_host}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -agF status-right "#[fg=#{@thm_yellow}]#{@catppuccin_status_left_separator}#[fg=#{@thm_crust},bg=#{@thm_yellow}]RAM #[fg=#{@thm_fg},bg=#{@catppuccin_status_module_text_bg}] ##{ram_percentage}#[fg=#{@catppuccin_status_module_text_bg}]#{@catppuccin_status_right_separator}"
          set -ag status-right "#{E:@catppuccin_status_date_time}"
          set -ag status-right " #{continuum_status}"
        '';
      }
    ];

    extraConfig = ''
      set -g exit-empty off

      set -g prefix2 C-t
      bind-key C-t send-prefix -2

      setw -g xterm-keys on
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -g set-clipboard external

      bind-key -T copy-mode-vi q send-keys -X cancel
      bind-key -T copy-mode-vi C-c send-keys -X cancel
      bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel

      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key h select-pane -L
      bind-key l select-pane -R

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
      bind -n C-M-n next-window
      bind -n C-M-p previous-window

      bind -n M-H resize-pane -L 5
      bind -n M-J resize-pane -D 5
      bind -n M-K resize-pane -U 5
      bind -n M-L resize-pane -R 5
      bind -n M-N swap-window -t +1 \; select-window -t +1
      bind -n M-P swap-window -t -1 \; select-window -t -1

      bind r source-file ${tmuxConfig}

      bind s split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"

      # floating pane (tmux 3.7); overrides default `prefix f` find-window
      bind f new-pane -c "#{pane_current_path}"
      # keep find-window, moved from the now-overridden `f`
      bind F command-prompt { find-window -Z "%%" }

      bind m command-prompt -p "join pane to window:" "join-pane -t ':%%'"
      bind M set -g mouse \; display "Mouse #{?mouse,ON,OFF}!"

      set -g status on
      set -g status-interval 5
      set -g status-justify left

      setw -g pane-border-status top
      setw -g pane-border-format '#{pane_index} #{pane_current_command} #{b:pane_current_path}'

      set -g set-titles on
      set -g set-titles-string '#(whoami)@#h :: [#S]'

      setw -g automatic-rename on
      setw -g automatic-rename-format '#{pane_current_command}:#{b:pane_current_path}'

      set -g update-environment "SSH_AUTH_SOCK"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g allow-passthrough on

      bind-key Space show-wk-menu-root
    '';
  };

  home.activation = lib.mkIf pkgs.stdenv.isLinux {
    ## Preserve continuum's mutable unit before linkGeneration force-replaces it.
    stageLegacyTmuxService = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      _hmTmuxMigrationDir=
      _hmTmuxOldGenPath=

      if [[ -v oldGenPath ]]; then
        _hmTmuxOldGenPath=$oldGenPath
        _hmTmuxOldUnitsDir="$oldGenPath/home-files/.config/systemd/user"
        _hmTmuxNewUnit="$newGenPath/home-files/.config/systemd/user/tmux.service"
        _hmTmuxLiveUnit="$HOME/.config/systemd/user/tmux.service"

        if [[ ! -e "$_hmTmuxOldUnitsDir/tmux.service" \
          && -e "$_hmTmuxNewUnit" \
          && -f "$_hmTmuxLiveUnit" \
          && ! -L "$_hmTmuxLiveUnit" ]] \
          && env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
            ${config.systemd.user.systemctlPath} --user --quiet is-active tmux.service
        then
          _hmTmuxMigrationDir=$(mktemp -d)
          _hmTmuxMigrationUnitsDir="$_hmTmuxMigrationDir/home-files/.config/systemd/user"
          mkdir -p "$_hmTmuxMigrationUnitsDir"
          if [[ -d "$_hmTmuxOldUnitsDir" ]]; then
            cp -a "$_hmTmuxOldUnitsDir/." "$_hmTmuxMigrationUnitsDir/"
            chmod -R u+w "$_hmTmuxMigrationUnitsDir"
          fi
          cp -- "$_hmTmuxLiveUnit" "$_hmTmuxMigrationUnitsDir/tmux.service"
        fi
      fi
    '';

    ## Let sd-switch adopt the active legacy service without stopping it once.
    adoptLegacyTmuxService =
      lib.hm.dag.entryBetween
        [ "reloadSystemd" ]
        [
          "linkGeneration"
          "stageLegacyTmuxService"
        ]
        ''
          if [[ -n "$_hmTmuxMigrationDir" ]]; then
            oldGenPath=$_hmTmuxMigrationDir
          fi
        '';

    cleanupLegacyTmuxService =
      lib.hm.dag.entryAfter
        [
          "reloadSystemd"
          "adoptLegacyTmuxService"
        ]
        ''
          if [[ -n "$_hmTmuxMigrationDir" ]]; then
            oldGenPath=$_hmTmuxOldGenPath
            rm -rf -- "$_hmTmuxMigrationDir"
          fi
          unset _hmTmuxMigrationDir _hmTmuxMigrationUnitsDir _hmTmuxOldGenPath
          unset _hmTmuxOldUnitsDir _hmTmuxNewUnit _hmTmuxLiveUnit
        '';
  };

  systemd.user.services = lib.mkIf pkgs.stdenv.isLinux {
    ## Keep continuum's boot service declarative so start and stop use the same secure socket.
    tmux = {
      Unit = {
        Description = "tmux server for continuum restore";
        Documentation = [ "man:tmux(1)" ];
        X-SwitchMethod = "keep-old";
      };

      Service = {
        Type = "forking";
        Environment = [
          "DISPLAY=:0"
          "TMUX_TMPDIR=%t"
        ];
        ExecStart = "${tmuxBin} start-server";
        ExecStop = [
          "-${resurrectSave}"
          "${tmuxBin} kill-server"
        ];
        KillMode = "control-group";
        RestartSec = 2;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };

  ## Replace the legacy unit generated by tmux-continuum during activation.
  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    "systemd/user/tmux.service".force = true;
    "systemd/user/default.target.wants/tmux.service".force = true;
  };
}
