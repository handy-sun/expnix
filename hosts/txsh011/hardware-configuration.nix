# Placeholder written by hand, NOT by ‘nixos-generate-config’: this host is
# not provisioned yet. Once it is, replace this file with the generated
# /etc/nixos/hardware-configuration.nix (the root device below is a guess).
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sr_mod"
    "virtio_blk"
    "ahci"
    "xen_blkfront"
    "vmw_pvscsi"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9d4fb838-720c-4bc5-9e53-63271b2e8925";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
