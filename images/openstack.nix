{ config, pkgs, lib, ... }:

{
  imports = [
    ../hardware/openstack.nix
    ../common/default.nix
  ];

  phenix.paranoid.enable = true;
}
