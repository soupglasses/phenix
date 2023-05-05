{
  config,
  pkgs,
  ...
}: {
  sops.secrets."restic/password".sopsFile = ../secrets/restic.yaml;
  sops.secrets."restic/environment".sopsFile = ../secrets/restic.yaml;

  services.restic.backups.minecraft = {
    initialize = true;
    passwordFile = config.sops.secrets."restic/password".path;
    environmentFile = config.sops.secrets."restic/environment".path;
    repository = "b2:imsofi-infra:minecraft";
    paths = ["/var/lib/minecraft"];
    pruneOpts = ["--keep-daily 31"];
    timerConfig = {
      OnCalendar = "06:30";
      RandomizedDelaySec = "30m";
    };
    backupPrepareCommand = ''
      echo "say Starting backup..." > /run/minecraft-server.stdin
      echo save-off > /run/minecraft-server.stdin
      echo save-all > /run/minecraft-server.stdin
      sleep 5
    '';
    backupCleanupCommand = ''
      echo save-on > /run/minecraft-server.stdin
      echo "say Backup complete!" > /run/minecraft-server.stdin
    '';
  };

  systemd.services.restic-backups-minecraft = {
    partOf = ["minecraft-server.service"];
    requisite = ["minecraft-server.service"];
    after = ["minecraft-server.service"];
  };

  services.minecraft-server = {
    enable = true;
    declarative = false;
    eula = true;
    dataDir = "/var/lib/minecraft/queer-gaymers";
    openFirewall = true;
    package = pkgs.fabricServers.fabric-1_19_4;
    jvmOpts = builtins.concatStringsSep " " [
      "-XX:+UnlockExperimentalVMOptions"
      "-XX:+UseShenandoahGC"
      "-XX:ShenandoahGCMode=iu"
      "-XX:+UseNUMA"
      "-XX:+AlwaysPreTouch"
      "-XX:+DisableExplicitGC"
      "-Xms2G"
      "-Xmx2G"
      "-server"
    ];
  };
}
