{ config, lib, pkgs, ... }:
{
  imports = [
    # Server configuration
    ../../common/default.nix
    ../../hardware/qemu.nix
    # Secret management
    ./sops.nix                       
    # Web services
    ./modules/acme.nix
    ./modules/nginx.nix               # requires: acme.nix
    ./modules/monitoring/default.nix  # requires: nginx.nix
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";

  users.mutableUsers = false;
  sops.secrets."root/password".neededForUsers = true;
  users.users."root" = {
    password = null; 
    initialHashedPassword = null;
    passwordFile = config.sops.secrets."root/password".path;
  };
}
