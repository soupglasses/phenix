{ config, lib, pkgs, ... }:
{
  users.users.authentik = {
    uid = 993;
    description = "Authetnik service user";
    home = "/var/lib/authentik";
    createHome = true;
    isSystemUser = true;
    group = config.users.groups.authentik.name;
    subUidRanges = [
      { startUid = 100000; count = 65536; }
    ];
    subGidRanges = [
      { startGid = 100000; count = 65536; }
    ];
  };

  users.groups.authentik.gid = 990;

  systemd.tmpfiles.rules = [
    "d /var/lib/authentik/media            0750 authentik authentik - -"
    "d /var/lib/authentik/custom-templates 0750 authentik authentik - -"
    "d /var/lib/authentik/certs            0750 authentik authentik - -"
  ];

  sops.secrets."authentik/secret_key" = {
    owner = config.users.users.authentik.name;
  };

  services.postgresql = {
    ensureDatabases = [ "authentik" ];
    ensureUsers = [{
      name = "authentik";
      ensurePermissions = {
        "DATABASE authentik" = "ALL PRIVILEGES";
      };
    }];
    authentication = ''
      host authentik authentik samehost trust
    '';
  };

  services.redis.servers."authentik" = {
    enable = true;
    user = "authentik";
    bind = "127.0.0.1";
    port = 6379;
  };

  systemd.services."podman-authentik-server" = {
    after = [ "postgresql.service" "redis-authentik.service" ];
    requires = [ "postgresql.service" "redis-authentik.service" ];
  };

  virtualisation.oci-containers.containers."authentik-server" = {
    image = "ghcr.io/goauthentik/dev-server:gh-next";
    cmd = [ "server" ];
    user = "${toString config.users.users.authentik.uid}:${toString config.users.groups.authentik.gid}";
    extraOptions = [
      #"--net=podnetwork"
      #"--ip=10.89.1.30"
      "--userns=keep-id"
      "--network=slirp4netns:allow_host_loopback=true"
    ];
    volumes = [
      "/var/lib/authentik/media:/media"
      "/var/lib/authentik/custom-templates:/templates"
      "/run/secrets/authentik/secret_key:/secrets/secret_key:ro"
    ];
    environment = {
      PUID = "${(toString config.users.users.authentik.uid)}";
      PGID = "${(toString config.users.groups.authentik.gid)}";
      AUTHENTIK_SECRET_KEY = "file:///secrets/secret_key";
      AUTHENTIK_REDIS__HOST = "10.0.2.2";
      AUTHENTIK_REDIS__PORT = (toString config.services.redis.servers.authentik.port);
      AUTHENTIK_POSTGRESQL__HOST = "10.0.2.2";
      AUTHENTIK_POSTGRESQL__USER = "authentik";
      AUTHENTIK_POSTGRESQL__NAME = "authentik";
      AUTHENTIK_POSTGRESQL__PASSWORD = "";
      AUTHENTIK_OUTPOSTS__DISCOVER = "false";
    };
  };

  virtualisation.oci-containers.containers."authentik-worker" = {
    image = "ghcr.io/goauthentik/dev-server:gh-next";
    dependsOn = [ "authentik-server" ];
    cmd = [ "worker" ];
    user = "${toString config.users.users.authentik.uid}:${toString config.users.groups.authentik.gid}";
    extraOptions = [
      #"--net=podnetwork"
      #"--ip=10.89.1.31"
      "--userns=keep-id"
      "--network=slirp4netns:allow_host_loopback=true"
    ];
    volumes = [
      "/var/lib/authentik/media:/media"
      "/var/lib/authentik/certs:/certs"
      "/var/lib/authentik/custom-templates:/templates"
      "/run/secrets/authentik/secret_key:/secrets/secret_key:ro"
    ];
    environment = {
      PUID = "${(toString config.users.users.authentik.uid)}";
      PGID = "${(toString config.users.groups.authentik.gid)}";
      AUTHENTIK_SECRET_KEY = "file:///secrets/secret_key";
      AUTHENTIK_REDIS__HOST = "10.0.2.2";
      AUTHENTIK_REDIS__PORT = (toString config.services.redis.servers.authentik.port);
      AUTHENTIK_POSTGRESQL__HOST = "10.0.2.2";
      AUTHENTIK_POSTGRESQL__USER = "authentik";
      AUTHENTIK_POSTGRESQL__NAME = "authentik";
      AUTHENTIK_POSTGRESQL__PASSWORD = "";
      AUTHENTIK_OUTPOSTS__DISCOVER = "false";
    };
  };
}
