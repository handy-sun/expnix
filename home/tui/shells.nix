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
  home.sessionPath = lib.mkIf enableGenericLinuxPath [
    "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/bin"
    "${config.home.profileDirectory}/bin"
    "/run/current-system/sw/bin"
    "/run/system-manager/sw/bin"
  ];

  programs.bash = {
    enable = true;
    initExtra = lib.mkAfter ''
      ## old nixpkgs' dev shell dlopen will failed, this local version requires GLIBC 2.15
      enable flyline 2>/dev/null || enable -f "$HOME/.local/lib/libflyline.so" flyline
    '';
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };

  programs.fish = {
    enable = true;
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
