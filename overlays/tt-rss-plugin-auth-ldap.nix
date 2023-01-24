_final: prev: {
  tt-rss-plugin-auth-ldap = prev.tt-rss-plugin-auth-ldap.overrideAttrs (old: rec {
    patches =
      old.patches
      ++ [
        # Change to non-deprecated logging function - https://github.com/hydrian/TTRSS-Auth-LDAP/pull/46
        (prev.fetchpatch {
          url = "https://github.com/imsofi/TTRSS-Auth-LDAP/commit/d876f958ab5c4861a318266ee5fcd1d79479b2ab.patch";
          sha256 = "sha256-OMne8zOznFNPcAPA2/3NHQ99gocW4X7GdTv/3FKfkMU=";
        })
      ];
  });
}
