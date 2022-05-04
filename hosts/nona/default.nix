{ config, pkgs, ... }:
{
  imports = [
    ../../common
    ../../hardware/qemu.nix

    ./nginx.nix
    ./monitoring.nix
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";
}
