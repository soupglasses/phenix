{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.canaille;
  format = pkgs.formats.toml {};
  configFile = format.generate "canaille-config.toml" cfg;
in {
  options.services.canaille = {
    enable = mkEnableOption (mdDoc "canaille");

    settings = mkOption {
      description = mdDoc ''
        Configuration of Canaille.
        You can use `_FILE` on any key to load its value from a file.
        See [canaille's configuration docs](https://gitlab.com/yaal/canaille/-/blob/main/doc/configuration.rst) for all available options.
      '';
      default = {};
      example = {
        SECRET_KEY_FILE = "/run/secret";
        LDAP = {
          URI = "ldap://ldap";
          ROOT_DN = "dc=mydomain,dc=tld";
          BIND_DN = "cn=admin,dc=mydomain,dc=tld";
          BIND_PW_FILE = "/run/secret-pw";
          USER_BASE = "ou=users,dc=mydomain,dc=tld";
          GROUP_BASE = "ou=groups,dc=mydomain,dc=tld";
        };
      };
      type = format.type;
    };

    package = mkOption {
      type = types.package;
      defaultText = "pkgs.canaille";
      description = lib.mdDoc "canaille package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/canaille";
      description = mdDoc "The directory where Canaille will store its configuration.";
    };
  };

  config = mkIf cfg.enable {
    services.canaille.settings = {
      JWT.PRIVATE_KEY = mkDefault "/var/lib/canaille/keys/private.pem";
      JWT.PUBLIC_KEY = mkIf (cfg.settings.JWT.PRIVATE_KEY == "/var/lib/canaille/keys/private.pem") "/var/lib/canaille/keys/public.pem";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 canaille canaille - -"
    ];

    users.users.canaille = {
      group = "canaille";
      isSystemUser = true;
    };
    users.groups.canaille = {};

    services.openldap.settings.children."cn=schema".includes = [
      "${cfg.package}/etc/schema/oauth2-openldap.ldif"
    ];

    systemd.services.canaille-setup = let
      setupScript = pkgs.writeShellScript ''
        umask 047

        mkdir -p /var/lib/canaille/keys

        if [ ! -f /var/lib/canaille/keys/private.pem ]; then
          openssl genrsa -out /var/lib/canaille/keys/private.pem 4096
          openssl rsa -in /var/lib/canaille/keys/private.pem -pubout -outform PEM -out /var/lib/canaille/keys/public.pem
        fi
      '';
    in
      mkIf (
        cfg.settings.JWT.PRIVATE_KEY == "/var/lib/canaille/keys/private.pem"
      )
      {
        wantedBy = ["multi-user.target"];
        before = ["canaille.service"];
        serviceConfig = {
          User = "canaille";
          Group = "canaille";
          ExecStart = setupScript;
          Type = "oneshot";
        };
      };

    systemd.services.canaille = {
      description = "Canaille";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment.CONFIG = "${configFile}";
      serviceConfig = mkMerge [
        {
          User = "canaille";
          Group = "canaille";
          # WARNING: Development instance. Should move to uwsgi.
          ExecStart = "${cfg.package}/bin/canaille run";
          Restart = "on-failure";
          RuntimeDirectory = "canaille";
        }
        (mkIf (cfg.dataDir == "/var/lib/canaille") {
          StateDirectory = "canaille";
          StateDirectoryMode = "0750";
        })
        {
          # Hardening
          #CapabilityBoundingSet = "";
          #NoNewPrivileges = true;
          #PrivateDevices = true;
          #PrivateTmp = true;
          #PrivateMounts = true;
          #ProtectHome = true;
          #ProtectClock = true;
          #ProtectProc = "noaccess";
          #ProcSubset = "pid";
          #ProtectKernelLogs = true;
          #ProtectKernelModules = true;
          #ProtectKernelTunables = true;
          #ProtectControlGroups = true;
          #ProtectHostname = true;
          #RestrictSUIDSGID = true;
          #RestrictRealtime = true;
          #RestrictNamespaces = true;
          #LockPersonality = true;
          #RemoveIPC = true;
          #RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
          #SystemCallFilter = ["@system-service" "~@privileged"];
        }
      ];
    };
  };
}
