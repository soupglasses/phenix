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
    extraOptions = {
      DATAPROXY_MAX_IDLE_CONNECTIONS = "100000";
    };
  };
}
