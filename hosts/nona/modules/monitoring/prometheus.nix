{
  config,
  lib,
  pkgs,
  ...
}: {
  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
    ];
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9002;
      };
    };
  };
}
