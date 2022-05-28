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
  security.acme.certs."watch.byte.surf".group = "nginx";
  security.acme.certs."ldap.byte.surf".group = "openldap";

  security.dhparams.enable = true;
  security.dhparams.params.nginx.bits = 1024;
  security.dhparams.params.openldap.bits = 1024;

  sops.secrets."acme/cloudflare_dns_api_key" = {
    owner = config.users.users.acme.name;
    sopsFile = ../secrets/acme.yaml;
  };
}
