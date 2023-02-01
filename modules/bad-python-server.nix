{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.phenix.bad-python-server;
in {
  options.services.phenix.bad-python-server = {
    enable = mkEnableOption "Enable bad-python-server service";

    package = mkOption {
      type = types.package;
      default = pkgs.phenix.bad-python-server;
      defaultText = "pkgs.phenix.bad-python-server";
      description = "The spessific bad-python-server package to use";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.bad-python-server = {
      description = "Bad Python Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      unitConfig = {
        StartLimitBurst = 2;
        StartLimitIntervalSec = 5;
      };

      serviceConfig = {
        DynamicUser = true;
        Type = "notify";
        NotifyAccess = "exec";
        Restart = "on-failure";
        WatchdogSec = 15;
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '${pkgs.phenix.systemd-http-health-check}/bin/systemd_http_health_check "http://localhost:8080/health" \
          & exec ${cfg.package}/bin/bad-python-server'
        '';
      };
    };
  };
}
