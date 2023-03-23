{
  config,
  pkgs,
  options,
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

  services.redis.servers.nextcloud = {
    enable = true;
    user = "nextcloud";
    port = 0;
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
    requires = ["postgresql.service" "redis-nextcloud.service"];
    after = ["postgresql.service" "redis-nextcloud.service"];
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
    enableBrokenCiphersForSSE = false; # Use openssl 3
    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      adminuser = "operator";
      adminpassFile = config.sops.secrets."nextcloud/admin-password".path;
      defaultPhoneRegion = "DK";
    };
    caching.redis = true;
    caching.apcu = false;
    extraOptions = {
      redis = {
        host = "/run/redis-nextcloud/redis.sock";
        port = 0;
      };
      "memcache.local" = "\\OC\\Memcache\\Redis";
      "memcache.distributed" = "\\OC\\Memcache\\Redis";
      "memcache.locking" = "\\OC\\Memcache\\Redis";
    };
    poolSettings = {
      "pm" = "dynamic";
      "pm.max_children" = "48";
      "pm.start_servers" = "16";
      "pm.min_spare_servers" = "8";
      "pm.max_spare_servers" = "16";
      "pm.max_requests" = "200";
    };
    phpOptions =
      options.services.nextcloud.phpOptions.default
      // {
        "zend_extension" = "opcache.so";
        "opcache.revalidate_freq" = "60";
        "opcache.interned_strings_buffer" = "16";
        "opcache.save_comments" = "1";
        "opcache.jit" = "on";
        "opcache.jit_buffer_size" = "128M";
      };
  };
}
