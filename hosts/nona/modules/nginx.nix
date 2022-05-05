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
      # TODO: Figure out a way to do this with useACMEhost.
      enableACME = true;
      forceSSL = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    443 80
  ];
}
