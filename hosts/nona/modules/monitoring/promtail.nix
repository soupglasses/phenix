{ config, lib, pkgs, ... }:
{
  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 3101;
      server.grpc_listen_port = 0;

      clients = [
        { url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push"; }
      ];

      scrape_configs = [{
        job_name = "journal";
        journal = {
        #  json = true;
          max_age = "12h";
          labels.job = "systemd-journal";
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };
}
