{ config, lib, modulesPath, pkgs, ... }:
let
  inherit (lib) mkDefault mkForce;
in
{
  imports = [
    # Optimizations related to QEMU trough virtio drivers.
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # For SCSI CD ROM support
  boot.initrd.availableKernelModules = [ "sr_mod" ];
  # Stop the server from waiting for user input in a panic, just reboot.
  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  boot.loader.timeout = 1;
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "prohibit-password";
    passwordAuthentication = mkDefault false;
  };

  # Allow communication from guest to host.
  services.qemuGuest.enable = true;

  # Attempt to get hostname by DHCP.
  networking.hostName = mkDefault "";
}
