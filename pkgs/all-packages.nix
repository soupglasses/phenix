{pkgs}: {
  tt-rss-plugin-fever = pkgs.callPackage ./tt-rss-plugin-fever.nix {};
  systemd-http-health-check = pkgs.callPackage ./systemd-http-health-check.nix {};
  bad-python-server = pkgs.callPackage ./bad-python-server.nix {};
}
