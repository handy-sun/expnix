{
  lib,
  isWSL ? false,
  ...
}:
let
  atticdServerName = "fngo-nsm";
in
{
  programs = {
    nh = {
      enable = true;
      clean.enable = false;
      clean.extraArgs = "--keep-since 4d --keep 3";
    };

    # very fast version of tldr in Rust
    tealdeer = {
      enable = true;
      # WSL2 systemd user services May init failed
      enableAutoUpdates = !isWSL;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        updates = {
          auto_update = true;
          auto_update_interval_hours = 720;
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    htop = {
      enable = true;
      settings = {
        hide_userland_threads = 1;
        highlight_base_name = 1;
      };
    };

    # Keep man cache generation off even if upstream modules enable it by default.
    man.generateCaches = lib.mkForce false;

    attic-client = {
      enable = true;
      settings = {
        default-server = atticdServerName;
        servers.${atticdServerName} = {
          endpoint = "http://fngo:8480";
          token-file = "/etc/atticd-client.token"; # WARN: not producible
        };
      };
    };

    ## broot: tree explorer. programs.broot ships broot's own default template
    ## (special_paths etc. stay active) and merges `settings` into conf.hjson.
    broot = {
      enable = true;
      settings = {
        ## Three panels: tree | tree | preview. A new panel's type follows the
        ## selection when ctrl-right opens it: directory -> tree, file -> preview.
        max_panels_count = 3;
        ## Pin the middle (0-indexed 1) tree column; instructions for absent
        ## panels are inert, so single-panel sessions keep full width.
        layout_instructions = [
          {
            panel = 1;
            width = 55;
          }
        ];
        ## Carried over from the pre-HM hand-generated config.
        enable_kitty_keyboard = false;
      };
    };
  };
}
