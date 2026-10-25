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
  ## nixpkgs bumped mcp to 2.x, marking fastmcp-slim broken; pin mcp back to the
  ## 1.29.0 recipe nixpkgs still ships so fastmcp and its consumers evaluate.
  python3PackagesPinned =
    (pkgs.python3.override {
      packageOverrides = f: _p: {
        mcp = f.callPackage "${pkgs.path}/pkgs/development/python-modules/mcp/1.nix" { };
      };
    }).pkgs;

  rustAnalyzerMcp = pkgs.callPackage (myutils.relativeToRoot "packages/rust-analyzer-mcp.nix") {
    inherit inputs;
  };
  qtRulesMcp = pkgs.callPackage (myutils.relativeToRoot "packages/qt-rules-mcp.nix") {
    inherit inputs;
    python3Packages = python3PackagesPinned;
  };
  mcpNixos = pkgs.mcp-nixos.override { python3Packages = python3PackagesPinned; };
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
      mcpNixos
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
