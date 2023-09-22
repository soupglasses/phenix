{...}: {
  services.loki = {
    enable = false; # error initialising module: compactor, invalid ring lifecycler config
    configuration = {
      target = "all";
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
        grpc_listen_port = 9095;

        http_server_read_timeout = "60s"; # allow longer time span queries
        http_server_write_timeout = "60s"; # allow longer time span queries
        grpc_server_max_recv_msg_size = 33554432; # 32MiB (int bytes), default 4MB
        grpc_server_max_send_msg_size = 33554432; # 32MiB (int bytes), default 4MB

        log_level = "warn";
      };

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {store = "inmemory";};
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
          kvstore = {store = "inmemory";};
        };
      };

      schema_config.configs = [
        {
          from = "2020-05-15";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

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

      query_range.parallelise_shardable_queries = false;
      frontend.max_outstanding_per_tenant = 2048;
    };
  };

  systemd.services.loki.serviceConfig = {
    CacheDirectory = "loki";
    ReadWritePaths = "/var/cache/loki";
  };
}
