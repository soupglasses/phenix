{pkgs}: rec {
  tt-rss-plugin-fever = pkgs.callPackage ./tt-rss-plugin-fever.nix {};
  systemd-http-health-check = pkgs.callPackage ./systemd-http-health-check.nix {};
  bad-python-server = pkgs.callPackage ./bad-python-server.nix {};

  jellyfin-hardened-core = pkgs.callPackage ./jellyfin-hardened/core.nix {};
  jellyfin-hardened-ldap = pkgs.callPackage ./jellyfin-ldap {inherit jellyfin-hardened-core;};
  jellyfin-hardened-server = pkgs.callPackage ./jellyfin-hardened/server.nix {
    ffmpeg = pkgs.jellyfin-ffmpeg;
    inherit jellyfin-hardened-web;
  };
  jellyfin-hardened-web = pkgs.callPackage ./jellyfin-hardened/web.nix {};
}
