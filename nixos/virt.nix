{
  lib,
  pkgs,
  myvars,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiHeavy {
  ## Windows 10/11 guests via QEMU/KVM + libvirt + virt-manager.
  ## - OVMF (UEFI) is shipped with QEMU by default in current NixOS;
  ## - swtpm provides the emulated TPM 2.0 the Windows 11 installer requires;
  ## - virtio-win carries the VirtIO disk/network/balloon drivers for the guest;
  ## - virtiofsd enables shared folders between host and guest.
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };

  ## Adds virt-manager to PATH and preconfigures the qemu:///system
  ## connection (autoconnect) via dconf.
  programs.virt-manager.enable = true;

  ## The default libvirt NAT network (virbr0, 192.168.122.0/24) needs
  ## dnsmasq at runtime for DHCP/DNS.
  environment.systemPackages = with pkgs; [
    dnsmasq
    virt-viewer
    virtio-win
    spice-gtk
  ];

  ## polkit rule grants org.libvirt.unix.manage to members of this group.
  users.groups.libvirtd = { };
  users.users.${myvars.user}.extraGroups = [ "libvirtd" ];
}
