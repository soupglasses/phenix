{ config, lib, modulesPath, pkgs, ... }:
let
  inherit (lib) mkDefault mkForce;
in
{
  imports = [
    # Optimizations related to QEMU trough virtio drivers.
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  boot.growPartition = true;
  boot.loader.timeout = 1;
  boot.loader.grub.device = "/dev/vda";
  #boot.kernelModules = [ "kvm-amd" ];

  # Since we can't manually respond to a panic, just reboot.
  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  users.users.root.initialPassword = mkDefault "phenix";

  services.openssh = {
    enable = true;
    permitRootLogin = "prohibit-password";
    passwordAuthentication = mkDefault false;
  };

  networking.hostName = mkDefault "";
}
