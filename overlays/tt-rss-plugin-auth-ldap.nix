final: prev:
{
  tt-rss-plugin-auth-ldap = prev.tt-rss-plugin-auth-ldap.overrideAttrs (old: rec {
    patches = old.patches ++ [
      # Fix ldaps connect - https://github.com/hydrian/TTRSS-Auth-LDAP/pull/34
      (prev.fetchpatch {
        url = "https://github.com/hydrian/TTRSS-Auth-LDAP/commit/b1a873f6a7d18231d2ac804d0146d6e048c8382c.patch";
        sha256 = "sha256-t5bDQM97dGwr7tHSS9cSO7qApf2M8KNaIuIxbAjExrs=";
      })
      # Change to non-deprecated logging function - https://github.com/hydrian/TTRSS-Auth-LDAP/pull/46
      (prev.fetchpatch {
        url = "https://github.com/imsofi/TTRSS-Auth-LDAP/commit/d876f958ab5c4861a318266ee5fcd1d79479b2ab.patch";
        sha256 = "sha256-OMne8zOznFNPcAPA2/3NHQ99gocW4X7GdTv/3FKfkMU=";
      })
    ];
  });
}
