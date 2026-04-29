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
  home.packages =
    with pkgs;
    lib.optionals profileLevel.tuiAdvanced [
      ## build tools
      gnumake
      cmake
      ninja

      ## languages
      perl
      php
      pnpm

      ## LSP / dev tools
      tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
      just-lsp
      lua-language-server
      rust-analyzer

      ## Docker
      docker-compose
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit

      ## downloads / transfers
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      axel
      lrzsz

      ## archives (extras)
      cpio # Program to create or extract from cpio archives
      p7zip
      pigz # Parallel Implementation of GZip
      unrar-free

      ## benchmarking
      hyperfine
      miniserve

      ## disk / files
      ncdu
      tre-command

      ## monitoring
      iftop # network monitoring
      multitail

      ## formatting / styling
      stylua # lua format tool

      ## media
      ffmpeg
      imagemagick

      ## monitoring agent
      beszel

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
    ];
}
