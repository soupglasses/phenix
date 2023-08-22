{
  imports = [
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./ssh.nix
    ./users.nix
  ];

  # Allow sudo from the wheel group.
  security.sudo.enable = true;

  # Always clean out /tmp on boot.
  boot.tmp.cleanOnBoot = true;

  # Allow use of our own Nix cache.
  nix.settings.substituters = ["https://cache.garnix.io"];
  nix.settings.trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
}
