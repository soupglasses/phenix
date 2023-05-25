{
  config,
  pkgs,
  ...
}: {
  security.acme.acceptTerms = true;

  security.acme.defaults = {
    email = "sofi+acme@mailbox.org";
    dnsProvider = "cloudflare";
    dnsResolver = "9.9.9.9:53";
    credentialsFile = pkgs.writeText "credentials" ''
      CLOUDFLARE_DNS_API_TOKEN_FILE=${config.sops.secrets.cloudflare_token.path}
    '';
  };

  security.dhparams.enable = true;

  sops.secrets.cloudflare_token = {
    owner = config.users.users.acme.name;
    sopsFile = ../../../../../secrets/dns.yaml;
  };
}
