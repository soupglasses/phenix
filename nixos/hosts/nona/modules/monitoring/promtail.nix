{config, ...}: {
  # TODO: Find a better way to access nginx log files.
  users.users.promtail.extraGroups = ["nginx"];

  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 3101;
      server.grpc_listen_port = 0;

      positions.filename = "/tmp/positions.yaml";

      clients = [
        {url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";}
      ];

      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            # json = true;
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "nona";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }

        # from: https://grafana.com/grafana/dashboards/12559
        {
          job_name = "nginx";
          pipeline_stages = [
            {
              replace = {
                expression = "(?:[0-9]{1,3}\\.){3}([0-9]{1,3})";
                replace = "***";
              };
            }
          ];
          static_configs = [
            {
              targets = [
                "localhost"
              ];
              labels = {
                job = "nginx";
                host = "nona";
                "__path__" = "/var/log/nginx/json_access.log";
              };
            }
          ];
        }
      ];
    };
  };
}
