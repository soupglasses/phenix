{ pkgs, lib, config, ... }:
{
  services.openldap = {
    enable = true;
    urlList = [ "ldaps:///" ];

    settings.attrs = {
      olcTLSCertificateFile = ''${config.security.acme.certs."ldap.byte.surf".directory}/cert.pem'';
      olcTLSCertificateKeyFile = ''${config.security.acme.certs."ldap.byte.surf".directory}/key.pem'';
      olcTLSCACertificateFile = ''${config.security.acme.certs."ldap.byte.surf".directory}/chain.pem'';
      olcTLSDHParamFile = ''${config.security.dhparams.params.openldap.path}'';
      olcTLSCACertificatePath = "/etc/ssl/certs";
      olcTLSCipherSuite = "ECDHE-RSA-AES256-SHA384:AES256-SHA256:!RC4:HIGH:!MD5:!aNULL:!EDH:!EXP:!SSLV2:!eNULL";
      olcTLSProtocolMin = "3.3";
      olcTLSVerifyClient = "never";

      olcLogLevel = "-1";
    };

    settings.children = {
      "cn=schema".includes = [
        "${pkgs.openldap}/etc/schema/core.ldif"
        "${pkgs.openldap}/etc/schema/cosine.ldif"
        "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
        "${pkgs.openldap}/etc/schema/ppolicy.ldif"
      ];

      "olcDatabase={-1}frontend".attrs = {
        objectClass = [ "olcDatabaseConfig" "olcFrontendConfig" ];
        olcDatabase = "{-1}frontend";
        olcPasswordHash = "{ARGON2}";
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
        objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
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
               by group.exact="cn=admins,ou=groups,dc=byte,dc=surf"
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
        olcModuleLoad = [ "ppolicy" "pw-argon2" ];
      };
      "olcOverlay=ppolicy,olcDatabase={1}mdb".attrs = {
        objectClass = [ "olcOverlayConfig" "olcPPolicyConfig" ];
        olcOverlay = "ppolicy";
        olcPPolicyDefault = "cn=default,ou=policies,dc=byte,dc=surf";
        olcPPolicyHashCleartext = "TRUE";
        olcPPolicyUseLockout = "TRUE";
      };
    };
  };

  sops.secrets."openldap/rootpw" = {
    owner = "openldap";
    sopsFile = ../../../secrets/ldap.yaml;
  };
}
