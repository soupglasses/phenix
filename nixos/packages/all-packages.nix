{pkgs}: rec {
  bad-python-server = pkgs.callPackage ./bad-python-server {};

  systemd-http-health-check = pkgs.callPackage ./systemd-http-health-check {};

  tt-rss-plugin-fever = pkgs.callPackage ./tt-rss-plugin-fever {};

  jellyfin-hardened = pkgs.callPackage ./jellyfin-hardened/server.nix {
    ffmpeg = pkgs.jellyfin-ffmpeg;
    inherit jellyfin-hardened-web;
  };

  jellyfin-hardened-core = pkgs.callPackage ./jellyfin-hardened/core.nix {};

  jellyfin-hardened-plugin-ldap = pkgs.callPackage ./jellyfin-hardened/plugins/ldap {inherit jellyfin-hardened-core;};

  jellyfin-hardened-web = pkgs.callPackage ./jellyfin-hardened/web.nix {};
}
