## ============================================================
## tuiAdvanced — larger / more complex terminal programs
## ============================================================
{
  pkgs,
  lib,
  inputs,
  myutils,
  profileLevel,
  isLinux,
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
{
  home.packages = (
    with pkgs;
    lib.optionals profileLevel.tuiAdvanced [
      ## languages
      perl
      php
      pnpm
      zig

      ## LSP / dev tools
      tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
      just-lsp
      lua-language-server

      ## downloads / transfers
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      axel
      # lftp
      lrzsz

      ## archives (extras)
      cpio # Program to create or extract from cpio archives
      _7zip-zstd
      pigz # Parallel Implementation of GZip
      unrar-free

      ## disk / files
      gdu
      miniserve
      rclone

      ## monitoring
      iftop # network monitoring
      netwatch

      ## formatting / styling
      stylua # lua format tool

      ## media
      ffmpeg
      imagemagick
      yt-dlp

      ## dev tools
      devenv
      tokei
      doxygen

      ## nix extras
      nix-info
      nix-init
      nix-tree
      cachix # Command-line client for Nix binary cache hosting https://cachix.org

      ## MCP servers
      context7-mcp
      github-mcp-server
      mcp-nixos
      playwright-mcp
      mcp-server-sequential-thinking
      rustAnalyzerMcp
      qtRulesMcp

      ## productivity | misc
      bc
      fastfetch
      python314Packages.rapidocr
      hugo # static site generator
      glow # markdown previewer in terminal
      subversion # svn
      swtpm # TPM emulator
    ]
    ++ lib.optionals (profileLevel.tuiAdvanced && isLinux) [
      bubblewrap
      rldd
      virtiofsd
    ]
  );
}
