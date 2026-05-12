## ============================================================
## tuiAdvanced — larger / more complex terminal programs
## ============================================================
{
  pkgs,
  lib,
  profileLevel,
  ...
}:
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
      rust-analyzer

      ## downloads / transfers
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      axel
      lftp
      lrzsz

      ## archives (extras)
      cpio # Program to create or extract from cpio archives
      _7zip-zstd
      pigz # Parallel Implementation of GZip
      unrar-free

      ## disk / files
      miniserve

      ## monitoring
      iftop # network monitoring

      ## formatting / styling
      stylua # lua format tool

      ## media
      ffmpeg
      imagemagick

      ## dev tools
      devenv
      tokei
      doxygen

      ## nix extras
      nix-info
      nix-init
      nix-tree
      cachix # Command-line client for Nix binary cache hosting https://cachix.org

      ## productivity
      hugo # static site generator
      glow # markdown previewer in terminal
    ]
  );
}
