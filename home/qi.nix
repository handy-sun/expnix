{ pkgs, ... }:

{
  # remember to modify
  home.username = "qi";
  home.homeDirectory = "/home/qi";

  home.packages = with pkgs; [
    zoxide
    trash-cli
    caddy
    neofetch
    fastfetch
    # nnn # terminal file manager

    # archives, compression and decompression
    bzip2
    cpio # Program to create or extract from cpio archives
    gzip
    p7zip
    pigz # Parallel Implementation of GZip
    #rar # absent on aarch64, and not really needed
    unzip
    unrar-free
    xz
    zip
    zstd

    # utils
    xclip
    fzf
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq

    # utilities written in Rust
    bandwhich
    bat # cat
    broot
    delta # diff; also used of git
    dua
    duf # df
    dust # du; (`du-dust` name is depracated)
    eza # ls colorize more info
    fd # find
    hyperfine
    ncdu
    procs # ps
    ripgrep # recursively searches directories for a regex pattern
    sd # sed
    stylua # lua format tool
    tre-command
    uv # pip
    yazi # ranger

    # misc
    doxygen
    tree
    multitail
    poppler-utils
    tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
    nil # language server for Nix

    # productivity
    hugo # static site generator
    htop
    glow # markdown previewer in terminal
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
  ];

  home.sessionVariables = {
    TERM = "xterm-256color";
    PAGER = "less";
    LESS = "-RX";
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };

  home.file.".zshrc".text = ''
    source $HOME/.config/dotzsh/zshrc
  '';
  home.stateVersion = "26.05";
}
