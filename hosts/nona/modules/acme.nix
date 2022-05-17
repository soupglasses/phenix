{ config, pkgs, ... }:
{
  security.acme.acceptTerms = true;

  security.acme.defaults = {
    email = "sofi+acme@mailbox.org";
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    credentialsFile = config.sops.secrets."acme/cloudflare_dns_api_key".path;
  };

  security.acme.certs."byte.surf".group = "nginx";
  security.acme.certs."ldap.byte.surf".group = "nginx";

  sops.secrets."acme/cloudflare_dns_api_key" = {
    owner = config.users.users.acme.name;
    sopsFile = ../secrets/acme.yaml;
  };
}
