{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    sslDhparam = config.security.dhparams.params.nginx.path;
  };

  security.dhparams.params.nginx.bits = 1024;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
