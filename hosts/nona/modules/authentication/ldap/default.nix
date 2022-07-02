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
      ];

      "olcDatabase={-1}frontend".attrs = {
        objectClass = [ "olcDatabaseConfig" "olcFrontendConfig" ];
        olcDatabase = "{-1}frontend";
        olcPasswordHash = "{ARGON2}";
        olcAccess = [
          # Give admins manage access.
          ''{0}to dn.subtree="dc=byte,dc=surf"
                by group/groupOfUniqueNames/uniqueMember="cn=admin,ou=groups,dc=byte,dc=surf" manage stop
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
        olcRootPW.path = config.sops.secrets."ldap/root-password".path;
        olcRootDN = "cn=admin,dc=byte,dc=surf";
        olcSuffix = "dc=byte,dc=surf";
        olcAccess = [
          # Restrict access by IP addresses.
          ''{0}to *
                by peername.ip=127.0.0.1 none break''
          # Give admins write access.
          ''{1}to dn.subtree="dc=byte,dc=surf"
                by group/groupOfUniqueNames/uniqueMember="cn=admin,ou=groups,dc=byte,dc=surf" write
                by * none break''
          # Only grant password access for auth, and only allow users to change their own.
          ''{2}to attrs=userPassword
                by anonymous auth
                by self write''
          # Do not let anyone modify their own uid as they are used for the DN.
          # Also allow anonymous to read uid's for login.
          ''{3}to attrs=uid
                by anonymous read
                by users read''
          # Do not let anyone modify OUs, they are used for the DN.
          ''{4}to attrs=ou
                by users read''
          # Stop the authentication account from reading anything else.
          # This also stops anonymous.
          ''{5}to *
                by dn.exact="uid=auth,ou=system,dc=byte,dc=surf"
                  none
                by users none break''
          # Prevent DNs in ou=users from reading system accounts
          ''{6}to dn.subtree="ou=system,dc=byte,dc=surf"
                by dn.subtree="ou=users,dc=byte,dc=surf" none
                by users read''
          # Default rule: Allow DNs to modify their own records,
          # and read access to everyone else.
          ''{7}to *
                by self write
                by users read''
        ];
      };
      "cn=module".attrs = {
        objectClass = "olcModuleList";
        cn = "module";
        olcModuleLoad = [ "ppolicy" "argon2" ];
      };
      "olcOverlay=ppolicy,olcDatabase={1}mdb".attrs = {
        objectClass = [ "olcOverlayConfig" "olcPPolicyConfig" ];
        olcOverlay = "ppolicy";
        olcPPolicyDefault = "cn=password,ou=policies,dc=byte,dc=surf";
        olcPPolicyHashCleartext = "TRUE";
        olcPPolicyUseLockout = "TRUE";
      };
    };
  };

  security.acme.certs."ldap.byte.surf".group = "openldap";
  security.dhparams.params.openldap.bits = 1024;

  sops.secrets."ldap/root-password" = {
    owner = "openldap";
    sopsFile = ../../../secrets/ldap.yaml;
  };
}
