# TODO:

## Nix related

* For ldap, write a script or find a method to initialize users through.
  * Current required users for building:
    * `cn=auth,ou=system,dc=byte,dc=surf` with password from sops `ldap/auth-password`
    * `cn=ttrss,ou=system,dc=byte,dc=surf` with password from sops `ttrss/ldap-password`
    * TODO: `cn=jellyfin,ou=system,dc=byte,dc=surf` with password from sops `jellyfin/ldap-password`

* Figure out a better way to handle requirements for base modules.
  * Furthermore, figure out a more general module system that could be portable between hosts.

* Move package trust from ssh user to package signing.

## Backups
* Use restic
  * /var/db/
  * /var/lib/jellyfin/

# Services
* Auth frontend to help change passwords etc. for end users.
  * Authelia/Keycloack/Canaille?
