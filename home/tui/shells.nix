{
  lib,
  pkgs,
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

  programs.bash = {
    enable = true;
  };

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
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];
  };

  programs.dotzsh = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableFishPrompt = false;
    fishGreetingMode = "custom";
    enableZshIntegration = true;
  };

}
