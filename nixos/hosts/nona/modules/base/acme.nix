{
  config,
  pkgs,
  ...
}: {
  security.acme.acceptTerms = true;

  security.acme.defaults = {
    email = "sofi+acme@mailbox.org";
    dnsProvider = "desec";
    dnsResolver = "9.9.9.9:53";
    credentialsFile = pkgs.writeText "credentials" ''
      DESEC_TOKEN_FILE=${config.sops.secrets."acme/desec_token".path}
    '';
  };

  security.dhparams.enable = true;

  sops.secrets."acme/desec_token" = {
    owner = config.users.users.acme.name;
    sopsFile = ../../secrets/acme.yaml;
  };
}
