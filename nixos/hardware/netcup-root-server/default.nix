{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # TODO: Unsure if these are needed. Its a KVM machine.
  boot.initrd.availableKernelModules = [
    # Intel PATA/SATA controllers
    "ata_piix"
    # Universal Host Controller Interface
    "uhci_hcd"
    # SCSI Disk Driver
    "sd_mod"
    # SCSI CD_ROM Driver
    "sr_mod"
  ];

  # Just reboot when hitting a panic.
  boot.kernelParams = ["panic=1" "boot.panic_on_fail"];

  boot.loader.timeout = 5;
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3";
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "yes";
  };

  # Attempt to get hostname by DHCP.
  # TODO: Unsure if NetCup announces a DHCP name.
  networking.hostName = lib.mkDefault "";
}
