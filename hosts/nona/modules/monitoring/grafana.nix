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
    settings.server.root_url = "https://byte.surf/grafana/";
    settings.server.http_addr = "127.0.0.1";
    settings.server.http_port = 2342;
    settings.server.domain = "byte.surf";
    # for systemd environment: "DATAPROXY_MAX_IDLE_CONNECTIONS=10000"
  };
}
