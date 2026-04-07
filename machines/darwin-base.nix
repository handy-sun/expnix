{
  pkgs,
  lib,
  username,
  hostName,
  myvars,
  ...
}: let
  ## Homebrew Mirror
  homebrew_mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.ustc.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.ustc.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.ustc.edu.cn/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.ustc.edu.cn/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };
  homebrew_env_script =
    lib.attrsets.foldlAttrs (
      acc: name: value:
        acc + "\nexport ${name}=${value}"
    ) ""
    homebrew_mirror_env;
in {
  ###################################################################################
  #
  #  macOS's System configuration
  #
  #  All the configuration options are documented here:
  #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
  #
  ###################################################################################
  system = {
    stateVersion = 6;

    defaults = {
      ## default: null
      menuExtraClock.Show24Hour = true; # show 24 hour clock
    };
  };

  ## Set variables for you to manually install homebrew packages.
  environment.variables =
    myvars.commonEnv
    // homebrew_mirror_env
    // {
      ## Fix darwin Terminal - perl: warning: Setting locale failed.
      LC_CTYPE = "${myvars.langEnv}";
      LC_ALL = "${myvars.langEnv}";
    };

  ## Set environment variables for nix-darwin before run `brew bundle`.
  ## homebrew.text = lib.mkBefore "echo >&2 '${homebrew_env_script}' ${homebrew_env_script}";
  system.activationScripts.homebrew.text = lib.mkBefore ''
    ${homebrew_env_script}
  '';
  ## COMMAND: scutil --get ComputerName
  networking.computerName = hostName;
  system.defaults.smb.NetBIOSName = hostName;

  ## Create /etc/zshrc that loads the nix-darwin environment.
  ## this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.shells = with pkgs; [
    bashInteractive
    fish
    zsh
  ];

  ## Set this to false because i am using Determinate Nix.
  nix.enable = false;
  nix.gc.automatic = false;
  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  nix.settings.auto-optimise-store = false;

  # Fonts
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome
      # maple-mono.NF-CN
      # nerdfonts
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
      nerd-fonts.symbols-only # symbols icon only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
    ];
  };

  #############################################################
  #
  #  Host & Users configuration
  #
  #############################################################
  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };
  system.primaryUser = username;

  ##########################################################################
  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  ##########################################################################
  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    curl
    wget
    file
    tmux
    coreutils
    iproute2mac
    procps
    fakeroot
    openssl
    openssh
    nmap
    logrotate
    nginx
    frp
    sing-box
    mihomo
    smartmontools
    # cachix
  ];

  # DONE To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      ## 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    taps = [
      "homebrew/services"
    ];

    ## `brew install`
    brews = [
      "lunchy"
    ];

    ## `brew install --cask`
    casks = [
      "ghostty"
      "antigravity"
      # "launchcontrol" # Failed to fetch
    ];
  };
}
