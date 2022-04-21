{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.phenix.paranoid;
  ifNoexec = if cfg.noexec then [ "noexec" ] else [ ];
in {
  options.phenix.paranoid = {
    enable = mkEnableOption "enables ephemeral filesystems and limited persistence";
    noexec = mkEnableOption "enables every mount on the system except /nix being marked as noexec";
  };

  config = mkIf cfg.enable {
    fileSystems."/" = mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ] ++ ifNoexec;
    };

    fileSystems."/etc/nixos".options = ifNoexec;
    fileSystems."/srv".options = ifNoexec;
    fileSystems."/var/lib".options = ifNoexec;
    fileSystems."/var/log".options = ifNoexec;

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    fileSystems."/nix" = {
      device = "/dev/disk/by-label/nix";
      autoResize = true;
      fsType = "ext4";
    };

    boot.cleanTmpDir = true;

    environment.persistence."/nix/persist" = {
      directories = [
        "/etc/nixos"  # nixos config files, optional
        "/srv"        # service data
        "/var/lib"    # system service data
        "/var/log"    # system logs
      ];
    };

    environment.etc."ssh/ssh_host_rsa_key".source =
      "/nix/persist/etc/ssh/ssh_host_rsa_key";
    environment.etc."ssh/ssh_host_rsa_key.pub".source =
      "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
    environment.etc."ssh/ssh_host_ed25519_key".source =
      "/nix/persist/etc/ssh/ssh_host_ed25519_key";
    environment.etc."ssh/ssh_host_ed25519_key.pub".source =
      "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
    environment.etc."machine-id".source =
      "/nix/persist/etc/machine-id";
  };
}
