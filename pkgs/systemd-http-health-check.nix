{
  crystal,
  fetchFromGitHub,
  systemd,
  openssl,
}:
crystal.buildCrystalPackage rec {
  pname = "systemd-http-health-check";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "jhass";
    repo = "systemd_http_health_check";
    rev = "v${version}";
    hash = "sha256-c2PzuqFQqevX14cCpxvTJfd0eZTcMA6ch6ieoR2DC0g=";
  };

  format = "shards";

  # Does not support sanity tests through the `--help` argument.
  doInstallCheck = false;

  buildInputs = [systemd openssl];
}
