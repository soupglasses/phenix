{config, ...}: {
  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig.scrape_interval = "15s";
    retentionTime = "180d";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
      {
        job_name = "systemd";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.systemd.port}"];
          }
        ];
      }
    ];
    exporters = {
      node = {
        enable = true;
        port = 9002;
      };
      systemd = {
        enable = true;
        port = 9558;
      };
    };
  };
}
