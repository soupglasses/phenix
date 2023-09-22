{
  # Do not allow forwarding X11 (graphical) applications.
  services.openssh.settings.X11Forwarding = false;

  # Do not allow keyboard-interactive based authentication.
  services.openssh.settings.KbdInteractiveAuthentication = false;

  # Do not allow password based authentication.
  services.openssh.settings.PasswordAuthentication = false;

  # Do not allow logins against root user.
  services.openssh.settings.PermitRootLogin = "no";

  # Mozilla's Modern OpenSSH 6.7+ configuration.
  # Source: https://infosec.mozilla.org/guidelines/openssh
  services.openssh.settings.KexAlgorithms = [
    "curve25519-sha256@libssh.org"
    "ecdh-sha2-nistp521"
    "ecdh-sha2-nistp384"
    "ecdh-sha2-nistp256"
    "diffie-hellman-group-exchange-sha256"
  ];
  services.openssh.settings.Ciphers = [
    "chacha20-poly1305@openssh.com"
    "aes256-gcm@openssh.com"
    "aes128-gcm@openssh.com"
    "aes256-ctr"
    "aes192-ctr"
    "aes128-ctr"
  ];
  services.openssh.settings.Macs = [
    "hmac-sha2-512-etm@openssh.com"
    "hmac-sha2-256-etm@openssh.com"
    "umac-128-etm@openssh.com"
    "hmac-sha2-512"
    "hmac-sha2-256"
    "umac-128@openssh.com"
  ];

  # Make our own pseudo certificate authority for public ssh services.
  programs.ssh.knownHosts = {
    github.hostNames = ["github.com"];
    github.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

    gitlab.hostNames = ["gitlab.com"];
    gitlab.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";

    sourcehut.hostNames = ["git.sr.ht"];
    sourcehut.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";
  };
}
