{ config, pkgs, ... }:
{
  imports = [
    ../../common
    ../../hardware/qemu.nix
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";
}
