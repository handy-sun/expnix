{
  lib,
  pkgs,
  myutils,
  ...
}:
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/wsl-base.nix"
      "nixos"
    ]
  );

  nixpkgs.config.cudaSupport = true;

  wsl.useWindowsDriver = true;

  wsl.wslConf = {
    interop.appendWindowsPath = false;
    automount = {
      enabled = true;
      options = "";
      # options = lib.mkForce "";
      # mountFsTab = false; # 阻止 WSL 处理 fstab，可能能缓解抢跑冲突
    };
  };

  hardware.graphics.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  #   libglvnd
  #   egl-wayland
  #   mesa
  #   mesa.drivers
  #   mesa-demos
  # ];

  ## warning: not applying GID change of group ‘docker’ (997 -> 131) in /etc/group
  users.groups.docker.gid = lib.mkForce 997;

  services.sing-box.enable = lib.mkForce false;

  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
    openFirewall = true;
  };
}
