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
    rev = "b607be2aa428c34d26d699765d47f728e47585c9";
    hash = "sha256-6ohkrmrYTV6uJZxFmrd+M7BjyXmZ95/Z5jrNnJ+JNpI=";
  };

  format = "shards";

  # Does not support sanity tests through the `--help` argument.
  doInstallCheck = false;

  buildInputs = [systemd openssl];
}
