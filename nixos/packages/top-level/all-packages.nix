{pkgs}:
{
  bad-python-server = pkgs.callPackage ../servers/bad-python-server {};

  systemd-http-health-check = pkgs.callPackage ../tools/systemd-http-health-check {};
}
// {
  tt-rss-plugin-fever = pkgs.callPackage ../servers/tt-rss/plugin-fever {};
}
// rec {
  jellyfin = pkgs.callPackage ../servers/jellyfin-hardened/server.nix {
    ffmpeg = pkgs.jellyfin-ffmpeg;
    inherit jellyfin-web;
  };

  jellyfin-core = pkgs.callPackage ../servers/jellyfin-hardened/core.nix {};

  jellyfin-plugin-ldap = pkgs.callPackage ../servers/jellyfin-hardened/plugins/ldap {
    inherit jellyfin-core;
  };

  jellyfin-web = pkgs.callPackage ../servers/jellyfin-hardened/web.nix {};
}
