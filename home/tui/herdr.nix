{
  ...
}:

{
  ## Replaces zellij. Keeps the muscle memory: h/j/k/l focus, x close, z zoom,
  ## c/n/p tabs and a zellij-style `s` for split-down; no shell auto-start.
  programs.herdr = {
    enable = true;

    settings = {
      onboarding = false;

      terminal = {
        shell_mode = "auto";
        new_cwd = "follow";
      };

      theme.name = "catppuccin";

      ui = {
        sidebar_width = 30;
        agent_panel_sort = "priority";
        toast.delivery = "herdr";
        sound.enabled = false;
      };

      keys = {
        prefix = "ctrl+b";
        settings = "prefix+comma";
        split_horizontal = "prefix+s";
        detach = "prefix+d";
      };
    };
  };
}
