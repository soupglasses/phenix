# Design goals

This document is a work in progress, but attempts to capture all the design-ideas that phenix attempts to follow.

## Reproducibility

* Any server should be able to set itself up fully from nothing without manual intervention.
  * This means all databases must be able to be initialized through nix or another means deployed through a nix derivation.

* Failures should always propegate into a systemd service.
  * Failures should not be silent or only exist outside of systemd (ex. in docker). Systemd should be aware of all services.
  * Healthchecks should be present where possible/applicable inside of systemd.

* Avoid state where possible.
  * Choose or design services that require no stateful setup, all be possibly configured through nix.

* Document all important state's locations into `TODO.md`'s backup section.
  * Note for the future, all important state will be backed up, and this is a tempoary solution.

## Security

* All ssh keys must be password encrypted.
  * Follow the standard at: https://arc-lessons.github.io/security/04_sshkeys.html

* Avoid passwords/secrets if another means of authentication is possible.
  * Example: Use `ident` and `peer` based auth for postgres instead of the password based solution.

* Do not use security by obscurity.
  * The servers are all fully documented with their source code in this public repo. Any obscurity would be documented here, and therefore ruining any possible benefit said obscurity may have given.

* Apply security practices only where they are verifiable to apply.
  * Example: Do not put another password on sudo if there already is a authentication layer for password based ssh keys.
    * This behaviour says that we cannot trust the first layer of authentication, document why this would be verifiably true and not a "it feels more secure" approach.

* Follow the principle of least privilege.
  * Example: Do not give a system account the group `keys` to read from `/run/secrets`, rather change that spessific key's owner to said system account.
