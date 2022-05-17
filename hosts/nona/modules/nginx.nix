{ config, lib, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts."byte.surf" = {
      useACMEHost = "byte.surf";
      forceSSL = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    443 80
  ];
}
