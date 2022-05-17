{ config, pkgs, ... }:
let
  # WORKAROUND: https://discourse.nixos.org/t/weird-issue-with-acme-and-cloudflare-dns
  extraLegoFlags = [ "--dns.resolvers=8.8.8.8:53" ];
in
{
  security.acme.defaults.email = "sofi+acme@mailbox.org";
  security.acme.acceptTerms = true;

  security.acme.certs."byte.surf" = {
    group = "nginx";
    email = "sofi+acme@mailbox.org";
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets."acme/cloudflare_dns_api_key".path;
    inherit extraLegoFlags;
  };

  security.acme.certs."ldap.byte.surf" = {
    group = "nginx";
    email = "sofi+acme@mailbox.org";
    dnsProvider = "cloudflare";
    credentialsFile = config.sops.secrets."acme/cloudflare_dns_api_key".path;
    inherit extraLegoFlags;
  };

  sops.secrets."acme/cloudflare_dns_api_key" = {
    owner = config.users.users.acme.name;
    sopsFile = ../secrets/acme.yaml;
  };
}
