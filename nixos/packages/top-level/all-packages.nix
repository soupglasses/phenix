{pkgs}:
rec {
  flask-themer = pkgs.callPackage ../development/python-modules/flask-themer {};

  flask-webtest = pkgs.callPackage ../development/python-modules/flask-webtest {};

  slapd = pkgs.callPackage ../development/python-modules/slapd {};

  smtpdfix = pkgs.callPackage ../development/python-modules/smtpdfix {};

  canaille = pkgs.callPackage ../servers/canaille {
    inherit flask-themer flask-webtest slapd smtpdfix;
  };
}
// {
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
