{pkgs, ...}: {
  name = "canaille-check";
  nodes.machine = {config, ...}: {
    environment.etc."canaille/secret_key".text = "notasecret";
    services.canaille = {
      enable = true;
      settings = {
        SECRET_KEY_FILE = "/etc/canaille/secret_key";
      };
    };

    services.openldap = {
      enable = true;
      settings = {
        children = {
          "cn=schema".includes = [
            "${pkgs.openldap}/etc/schema/core.ldif"
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
            "${pkgs.openldap}/etc/schema/nis.ldif"
            "${config.services.canaille.package}/etc/schema/"
          ];
        };
      };
    };
  };
}
