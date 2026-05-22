## ============================================================
## tuiOptional — nice-to-have extras
## ============================================================
{
  pkgs,
  lib,
  inputs,
  profileLevel,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  helixDev = inputs.helix-dev.packages.${system}.helix;
  inherit (inputs.cc-switch-tui.packages.${system}) cc-switch-tui;
in
lib.mkIf profileLevel.tuiOptional {
  home.packages =
    with pkgs;
    [
      ## containers
      # podman
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
      ## https://github.com/erasin/helix more features more than official helix package
      helixDev
      llvmPackages.clang-unwrapped
      cc-switch-tui
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      btrfs-progs
      rldd
    ];
}
