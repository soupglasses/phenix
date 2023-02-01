{
  crystal,
  fetchFromGitHub,
  systemd,
  openssl,
}:
crystal.buildCrystalPackage rec {
  pname = "systemd-http-health-check";
  version = "2022-02-01";

  src = fetchFromGitHub {
    owner = "imsofi";
    repo = "systemd_http_health_check";
    rev = "4eb910dfc5cf4e87f6efb064f1d66c0d10550f95";
    hash = "sha256-MqbLQhWj+b04oDTZZoCYn1zwrLSdsrLB6wSF3Q7w4Ao=";
  };

  format = "shards";

  # Does not support sanity tests through the `--help` argument.
  doInstallCheck = false;

  buildInputs = [systemd openssl];
}
