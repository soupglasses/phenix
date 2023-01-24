{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    # Optimizations related to QEMU through virtio drivers.
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    # Intel PATA/SATA controllers
    "ata_piix"
    # Universal Host Controller Interface
    "uhci_hcd"
    # Virtio Virtual PCI Device
    "virtio_pci"
    # Virtio SCSI HBA driver
    "virtio_scsi"
    # SCSI Disk Driver
    "sd_mod"
    # SCSI CD_ROM Driver
    "sr_mod"
  ];

  # Just reboot when hitting a panic.
  boot.kernelParams = ["panic=1" "boot.panic_on_fail"];

  boot.loader.timeout = 1;
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/sda";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Attempt to get hostname by DHCP.
  networking.hostName = lib.mkDefault "";
}
