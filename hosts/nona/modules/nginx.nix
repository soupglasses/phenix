{ config, lib, pkgs, ... }:
{
  security.acme.defaults.email = "sofi+admin@mailbox.org";
  security.acme.acceptTerms = true;

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
