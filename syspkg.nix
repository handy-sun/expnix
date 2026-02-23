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
  programs.zsh.enable = true;
}
