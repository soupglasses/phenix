{ config, lib, pkgs, ... }:
{
  services.nginx = {
    virtualHosts."byte.surf".locations = {
      "/grafana/" = {
        proxyPass = "http://${config.services.grafana.addr}:${toString config.services.grafana.port}/";
        proxyWebsockets = true;
      };
    };
  };

  services.grafana = {
    enable = true;
    addr = "127.0.0.1";
    port = 2342;
    domain = "byte.surf";
    rootUrl = "https://byte.surf/grafana/";
  };

  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      server.grpc_listen_port = 9095;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = { store = "inmemory"; };
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
        max_transfer_retries = 0;
      };

      compactor = {
        working_directory = "/var/lib/loki";
        shared_store = "filesystem";
        compactor_ring = {
          kvstore = { store = "inmemory"; };
        };
      };

      schema_config.configs = [{
        from = "2020-05-15";
        store = "boltdb-shipper";
        object_store = "filesystem";
        schema = "v11";
        index = { prefix = "index_"; period = "24h"; };
      }];
      
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb";
          cache_location = "/var/cache/loki/boltdb";
          cache_ttl = "24h";
          shared_store = "filesystem";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config.reject_old_samples = true;
      limits_config.reject_old_samples_max_age = "24h";

      chunk_store_config.max_look_back_period = "0s";

      table_manager.retention_deletes_enabled = false;
      table_manager.retention_period = "0s";
    };
  };

  systemd.services.loki.serviceConfig.CacheDirectory = "loki";
  systemd.services.loki.serviceConfig.ReadWritePaths = "/var/cache/loki";

  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 3101;
      server.grpc_listen_port = 0;

      clients = [
        { url = "http://127.0.0.1:3100/loki/api/v1/push"; }
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
