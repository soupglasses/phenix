{ config, pkgs, ... }:
{
  sops.secrets."ttrss/ldap-password" = {
    owner = "tt_rss";
    sopsFile = ../secrets/ldap.yaml;
  };

  services.postgresql = {
    ensureDatabases = [ "tt_rss" ];
    ensureUsers = [{
      name = "tt_rss";
      ensurePermissions = {
        "DATABASE tt_rss" = "ALL PRIVILEGES";
      };
    }];
    # type, database, user, [address], auth-method, [auth-options]
    authentication = ''
      local tt_rss tt_rss peer
    '';
  };

  systemd.services.tt-rss = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  security.acme.certs."read.byte.surf".group = "nginx";
  services.nginx = {
    virtualHosts."read.byte.surf" = {
      useACMEHost = "read.byte.surf";
      forceSSL = true;
    };
  };

  services.phpfpm.pools.tt-rss.settings = {
    "pm" = "ondemand";
    "pm.max_children" = 32;
    "pm.process_idle_timeout" = "10s";
    "pm.max_requests" = 500;
  };

  services.tt-rss = {
    enable = true;
    virtualHost = "read.byte.surf";
    selfUrlPath = "https://read.byte.surf";

    pluginPackages = [
      pkgs.tt-rss-plugin-auth-ldap
    ];

    plugins = [
      "af_youtube_embed"
      "auth_internal"
      "auth_ldap"
      "note"
      "toggle_sidebar"
    ];

    database = {
      type = "pgsql";
      createLocally = false;
      name = "tt_rss";
      user = "tt_rss";
      password = null;
    };

    extraConfig = ''
      define('LDAP_AUTH_SERVER_URI', 'ldaps://ldap.byte.surf:636/');
      define('LDAP_AUTH_USETLS', TRUE);
      define('LDAP_AUTH_ALLOW_UNTRUSTED_CERT', FALSE);

      define('LDAP_AUTH_BASEDN', 'dc=byte,dc=surf');
      define('LDAP_AUTH_BINDDN', 'uid=ttrss,ou=system,dc=byte,dc=surf');
      define('LDAP_AUTH_BINDPW', file_get_contents('${config.sops.secrets."ttrss/ldap-password".path}'));
      define('LDAP_AUTH_ANONYMOUSBEFOREBIND', FALSE);

      define('LDAP_AUTH_LOGIN_ATTRIB', 'uid');
      // ??? will be replaced with the entered username(escaped) at login
      define('LDAP_AUTH_SEARCHFILTER', '(&(|(objectClass=inetOrgPerson))(|(uid=???)(|(mail=???))))');

      // For when things start to go wrong
      define('LDAP_AUTH_LOG_ATTEMPTS', FALSE);
      define('LDAP_AUTH_DEBUG', FALSE);
    '';
  };
}
