{ config, lib, pkgs, ... }:
{
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

  systemd.services.loki.serviceConfig = {
    CacheDirectory = "loki";
    ReadWritePaths = "/var/cache/loki";
  };
}
