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
    domain = "byte.surf";
    rootUrl = "https://byte.surf/grafana/";
  };
}
