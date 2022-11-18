{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets."nextcloud/admin-password" = {
    owner = "nextcloud";
    sopsFile = ../secrets/nextcloud.yaml;
  };

  # This is currently required to be put in manually.
  sops.secrets."nextcloud/ldap-password" = {
    owner = "nextcloud";
    sopsFile = ../secrets/ldap.yaml;
  };

  services.postgresql = {
    ensureDatabases = ["nextcloud"];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions = {
          "DATABASE nextcloud" = "ALL PRIVILEGES";
        };
      }
    ];
    # type, database, user, [address], auth-method, [auth-options]
    authentication = ''
      local nextcloud nextcloud peer
    '';
  };

  systemd.services.nextcloud-setup = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  security.acme.certs."cloud.byte.surf".group = "nginx";
  services.nginx.virtualHosts."cloud.byte.surf" = {
    useACMEHost = "cloud.byte.surf";
    forceSSL = true;
  };

  services.nextcloud = {
    package = pkgs.nextcloud25;
    enable = true;
    hostName = "cloud.byte.surf";
    https = true;
    phpExtraExtensions = all: [all.ldap];
    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      adminuser = "operator";
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      defaultPhoneRegion = "DK";
    };
  };
}
