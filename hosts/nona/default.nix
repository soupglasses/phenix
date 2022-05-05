{ config, pkgs, ... }:
{
  imports = [
    # Server configuration
    ../../common
    ../../hardware/qemu.nix
    # Secret management
    ./sops.nix
    # Web services
    ./nginx.nix
    ./monitoring.nix
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";
}
