{ config, lib, pkgs, ... }:
{
  imports = [
    # Server configuration
    ../../common/default.nix
    ../../hardware/qemu.nix
    # Secret management
    ./sops.nix
    # Containers
    ./modules/podman.nix
    # Databases
    ./modules/databases/postgres.nix
    # Web services
    ./modules/nginx.nix
    ./modules/monitoring/default.nix
    ./modules/authentik.nix
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
