{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Server configuration
    ../../kinds/server
    ../../hardware/netcup-root-server
    # Base configuration
    ./modules/base/acme.nix
    ./modules/base/nginx.nix # requires: base/acme.nix
    ./modules/base/postgresql.nix
    # Auth management
    ./modules/authentication/ldap # requires: base/acme.nix
    # Web services
    ./modules/nginx.nix # requires: base/acme.nix base/nginx.nix
    ./modules/monitoring/default.nix # requires: nginx.nix
    ./modules/ttrss.nix # requires: base/acme.nix base/nginx.nix base/postgresql.nix
    ./modules/jellyfin.nix # requires: base/acme.nix base/nginx.nix
    ./modules/nextcloud.nix # requires: base/acme.nix base/nginx.nix base/postgresql.nix
    # Game servers
    ./modules/minecraft.nix
  ];

  networking.hostName = "nona";
  networking.domain = "hosts.byte.surf";

  systemd.network.networks."10-wan".address = [
    "89.58.34.244/24"
    "2a03:4000:64:d3f::/64"
  ];

  networking.extraHosts = ''
    127.0.0.1 ldap.byte.surf
  '';

  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  sops.defaultSopsFile = ./secrets/main.yaml;

  users.mutableUsers = false;
  sops.secrets."root/password".neededForUsers = true;
  users.users."root" = {
    password = null;
    initialHashedPassword = null;
    hashedPasswordFile = config.sops.secrets."root/password".path;
  };

  environment.systemPackages = [
    pkgs.rsync
  ];

  boot.swraid.enable = false; # Badly implemented fallback enable, fixed in stateVersion 23.11.
  system.stateVersion = "22.05"; # Initially installed version. DO NOT TOUCH!
}
