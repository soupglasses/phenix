{ pkgs, lib, config, ... }:
{
  services.openldap = {
    enable = true;

    settings.attrs = {
      #olcLogLevel = "acl trace";
      olcLogLevel = "-1";
      # TODO: Migrate away from SHA-512
      olcPasswordHash = "{CRYPT}";
      olcPasswordCryptSaltFormat = "$6$%.16s";
    };

    settings.children = {
      "cn=schema".includes = [
        "${pkgs.openldap}/etc/schema/core.ldif"
        "${pkgs.openldap}/etc/schema/cosine.ldif"
        "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        "${pkgs.openldap}/etc/schema/ppolicy.ldif"
      ];

      "olcDatabase={-1}frontend".attrs = {
        objectClass = ["olcDatabaseConfig" "olcFrontendConfig"];
        olcDatabase = "{-1}frontend";
        olcAccess = [
          ''{0}to *
               by dn.exact="cn=admins,ou=groups,dc=byte,dc=surf" manage stop
               by * none stop''
        ];
      };
      "olcDatabase={0}config".attrs = {
        objectClass = "olcDatabaseConfig";
        olcDatabase = "{0}config";
        olcAccess = [ "{0}to * by * none break" ];
      };
      "olcDatabase={1}mdb".attrs = {
        objectClass = ["olcDatabaseConfig" "olcMdbConfig"];
        olcDatabase = "{1}mdb";
        olcDbDirectory = "/var/db/ldap";
        olcRootPW.path = config.sops.secrets."openldap/rootpw".path;
        olcRootDN = "cn=admin,dc=byte,dc=surf";
        olcSuffix = "dc=byte,dc=surf";
        # TODO: Indexes
        olcAccess = [
          ''{0}to attrs=userPassword
               by self       write
               by anonymous  auth
               by group.exact="cn=admins,ou=groups,dc=example,dc=com"
                             write
               by *          none''
          ''{1}to *
               by self     write
               by users    read
               by *        none''
        ];
      };
      "cn=module".attrs = {
        objectClass = "olcModuleList";
        cn = "module";
        olcModuleLoad = "ppolicy";
      };
      "olcOverlay=ppolicy,olcDatabase={1}mdb".attrs = {
        objectClass = ["olcOverlayConfig" "olcPPolicyConfig"];
        olcOverlay = "ppolicy";
        olcPPolicyDefault = "cn=default,ou=policies,dc=byte,dc=surf";
        olcPPolicyHashCleartext = "TRUE";
      };
    };
  };

  sops.secrets."openldap/rootpw" = {
    owner = "openldap";
    sopsFile = ../../../secrets/ldap.yaml;
  };
}
