{
  config,
  pkgs,
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
    package = pkgs.nextcloud27;
    enable = true;
    hostName = "cloud.byte.surf";
    https = true;
    maxUploadSize = "16G";
    phpExtraExtensions = all: [all.ldap all.opcache];
    enableBrokenCiphersForSSE = false; # Use openssl 3
    nginx.recommendedHttpHeaders = false;
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
    phpOptions = {
      "opcache.enable" = "1";
      "opcache.revalidate_freq" = "60";
      "opcache.interned_strings_buffer" = "16";
      "opcache.save_comments" = "1";
      "opcache.jit" = "on";
      "opcache.jit_buffer_size" = "128M";
    };
  };

  # Replace with `recommendedHttpHeaders` when: https://nixpk.gs/pr-tracker.html?pr=223182
  services.nginx.virtualHosts."cloud.byte.surf".extraConfig = ''
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag "noindex, nofollow";
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header X-Frame-Options sameorigin;
    add_header Referrer-Policy no-referrer;
  '';
}
