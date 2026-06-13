{ lib, isWSL ? false, ... }:
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

    # Keep man cache generation off even if upstream modules enable it by default.
    man.generateCaches = lib.mkForce false;
  };
}
