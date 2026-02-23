{ config, lib, pkgs, modulesPath, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux"; 
  networking.hostName = "expnix";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    dae
    glider
    sing-box
  ];
  # must enable zsh in order users to use it [[1
  programs.zsh.enable = true;
  users.users.qi = {
    shell = pkgs.zsh;
  };
  # ]]1

  time = {
    # timeZone = "Asia/Shanghai";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
    };
  };
}
