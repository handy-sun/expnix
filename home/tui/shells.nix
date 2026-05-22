{
  lib,
  config,
  isHmSingle,
  ...
}:
let
  enableGenericLinuxPath = isHmSingle;
in
{
  # home.sessionPath = lib.mkIf enableGenericLinuxPath [
  #   "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/bin"
  #   "${config.home.profileDirectory}/bin"
  #   "/run/current-system/sw/bin"
  #   "/run/system-manager/sw/bin"
  # ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };

  programs.fish = {
    enable = true;
    loginShellInit = lib.mkIf enableGenericLinuxPath ''
      set -l nix_state_dir /nix/var/nix
      set -q NIX_STATE_DIR; and set nix_state_dir $NIX_STATE_DIR

      fish_add_path --path --prepend \
        $nix_state_dir/profiles/default/bin \
        ${config.home.profileDirectory}/bin \
        /run/current-system/sw/bin \
        /run/system-manager/sw/bin
    '';
  };

  programs.dotzsh = {
    enable = true;
    enableFishIntegration = true;
    enableFishPrompt = isHmSingle;
    fishGreetingMode = "custom";
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = false;
    enableFishIntegration = true;
    enableZshIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      add_newline = false;
      line_break.disabled = true;
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };
      os.symbols = {
        NixOS = " ";
        Macos = " ";
        Debian = " ";
      };
      os.disabled = false;
      format = "\$os\$directory\$character";
      right_format = "\$all";
      # gcloud.disabled = true;
      # aws.disabled = true;
    };
  };
}
