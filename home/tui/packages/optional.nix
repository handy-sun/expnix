## ============================================================
## tuiOptional — nice-to-have extras
## ============================================================
{
  pkgs,
  lib,
  profileLevel,
  isLinux,
  inputs,
  myutils,
  ...
}:
let
  rustAnalyzerMcp = pkgs.callPackage (myutils.relativeToRoot "packages/rust-analyzer-mcp.nix") {
    inherit inputs;
  };
  qtRulesMcp = pkgs.callPackage (myutils.relativeToRoot "packages/qt-rules-mcp.nix") {
    inherit inputs;
  };
in
lib.mkIf profileLevel.tuiOptional {
  home.packages =
    with pkgs;
    [
      ## containers
      # podman
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit

      llvmPackages.clang-unwrapped
      cachix # Command-line client for Nix binary cache hosting https://cachix.org
      swtpm # TPM emulator

      ## MCP servers
      context7-mcp
      github-mcp-server
      mcp-nixos
      playwright-mcp
      mcp-server-sequential-thinking
      rustAnalyzerMcp
      qtRulesMcp
    ]
    ++ lib.optionals isLinux [
      btrfs-progs
      bubblewrap
      virtiofsd
    ];
}
