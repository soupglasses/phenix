{ config, lib, pkgs, ... }:
{
  imports = [
    # Server configuration
    ../../common/default.nix
    ../../hardware/qemu.nix
    # Secret management
    ./sops.nix
    # Auth mangement
    ./modules/authentication
    # Web services
    ./modules/acme.nix
    ./modules/nginx.nix               # requires: acme.nix
    ./modules/monitoring/default.nix  # requires: nginx.nix
    ./modules/jellyfin.nix            # requires: acme.nix nginx.nix
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

  environment.systemPackages = [
    pkgs.rsync
  ];

  system.stateVersion = "22.05";
}
