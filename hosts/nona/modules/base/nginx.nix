{
  config,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [80 443];

  security.dhparams.params.nginx.bits = 1024;

  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    sslDhparam = config.security.dhparams.params.nginx.path;

    commonHttpConfig = ''
      # Watch for changes in https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-servers/nginx/default.nix
      # recommendedTlsSettings without ssl_sesson_tickets.
      # Keep in sync with https://ssl-config.mozilla.org/#server=nginx&config=intermediate
      ssl_session_timeout 1d;
      ssl_session_cache shared:SSL:10m;
      # We don't enable insecure ciphers by default, so this allows
      # clients to pick the most performant, per https://github.com/mozilla/server-side-tls/issues/260
      ssl_prefer_server_ciphers off;
      # OCSP stapling
      ssl_stapling on;
      ssl_stapling_verify on;

      # Requires nginxMainline currently to be safe. https://github.com/mozilla/server-side-tls/issues/284
      ssl_session_tickets on;

      # Add HSTS Preloading. Re-add this to any location blocks if they include add_header blocks.
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Grafana https://grafana.com/grafana/dashboards/12559
      log_format json_analytics escape=json '{'
        '"msec": "$msec", ' # request unixtime in seconds with a milliseconds resolution
        '"connection": "$connection", ' # connection serial number
        '"connection_requests": "$connection_requests", ' # number of requests made in connection
        '"pid": "$pid", ' # process pid
        '"request_id": "$request_id", ' # the unique request id
        '"request_length": "$request_length", ' # request length (including headers and body)
        '"remote_addr": "$remote_addr", ' # client IP
        '"remote_user": "$remote_user", ' # client HTTP username
        '"remote_port": "$remote_port", ' # client port
        '"time_local": "$time_local", '
        '"time_iso8601": "$time_iso8601", ' # local time in the ISO 8601 standard format
        '"request": "$request", ' # full path no arguments if the request
        '"request_uri": "$request_uri", ' # full path and arguments if the request
        '"args": "$args", ' # args
        '"status": "$status", ' # response status code
        '"body_bytes_sent": "$body_bytes_sent", ' # the number of body bytes exclude headers sent to a client
        '"bytes_sent": "$bytes_sent", ' # the number of bytes sent to a client
        '"http_referer": "$http_referer", ' # HTTP referer
        '"http_user_agent": "$http_user_agent", ' # user agent
        '"http_x_forwarded_for": "$http_x_forwarded_for", ' # http_x_forwarded_for
        '"http_host": "$http_host", ' # the request Host: header
        '"server_name": "$server_name", ' # the name of the vhost serving the request
        '"request_time": "$request_time", ' # request processing time in seconds with msec resolution
        '"upstream": "$upstream_addr", ' # upstream backend server for proxied requests
        '"upstream_connect_time": "$upstream_connect_time", ' # upstream handshake time incl. TLS
        '"upstream_header_time": "$upstream_header_time", ' # time spent receiving upstream headers
        '"upstream_response_time": "$upstream_response_time", ' # time spend receiving upstream body
        '"upstream_response_length": "$upstream_response_length", ' # upstream response length
        '"upstream_cache_status": "$upstream_cache_status", ' # cache HIT/MISS where applicable
        '"ssl_protocol": "$ssl_protocol", ' # TLS protocol
        '"ssl_cipher": "$ssl_cipher", ' # TLS cipher
        '"scheme": "$scheme", ' # http or https
        '"request_method": "$request_method", ' # request method
        '"server_protocol": "$server_protocol", ' # request protocol, like HTTP/1.1 or HTTP/2.0
        '"pipe": "$pipe", ' # "p" if request was pipelined, "." otherwise
        '"gzip_ratio": "$gzip_ratio", '
        '"http_cf_ray": "$http_cf_ray",'
        '"geoip_country_code": "$geoip_country_code"'
      '}';

      access_log /var/log/nginx/json_access.log json_analytics;
    '';
  };
}
