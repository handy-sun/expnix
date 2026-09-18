## ============================================================
## tuiAdvanced — larger / more complex terminal programs
## ============================================================
{
  pkgs,
  lib,
  profileLevel,
  isLinux,
  ...
}:
{
  home.packages = (
    with pkgs;
    lib.optionals profileLevel.tuiAdvanced [
      ## languages
      go
      perl
      php
      pnpm

      ## LSP / dev tools
      tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
      just-lsp
      lua-language-server

      ## downloads / transfers
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      axel
      lrzsz

      ## archives (extras)
      cpio # Program to create or extract from cpio archives
      _7zip-zstd
      pigz # Parallel Implementation of GZip
      unrar-free

      ## disk / files
      fzf
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

      ## productivity | misc
      bc
      fastfetch
      python314Packages.rapidocr
      hugo # static site generator
      glow # markdown previewer in terminal
      subversion # svn
      chase
    ]
    ++ lib.optionals (profileLevel.tuiAdvanced && isLinux) [
      rldd
    ]
  );
}
