{config, ...}: {
  services.nginx = {
    virtualHosts."byte.surf".locations = {
      "/grafana/" = {
        proxyPass = "http://${
          config.services.grafana.settings.server.http_addr
        }:${toString config.services.grafana.settings.server.http_port}/";
        proxyWebsockets = true;
      };
      "= /grafana/metrics" = {
        extraConfig = ''
          allow 127.0.0.1;
          deny all;
        '';
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
