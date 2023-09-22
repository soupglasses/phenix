{
  config,
  pkgs,
  lib,
  ...
}: {
  # Use most up to date nix package.
  nix.package = pkgs.nixUnstable;

  # Fallback quickly if a substituter is not available.
  nix.settings.connect-timeout = 5;

  # Always enable flakes.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allows users in the wheel group to be ultimately trusted, so we can push unsigned NARs.
  # TODO: Use signature verification for NARs.
  nix.settings.allowed-users = ["root" "@wheel"];
  nix.settings.trusted-users = ["root" "@wheel"];

  # Extend default 10 lines of logs.
  nix.settings.log-lines = lib.mkDefault 25;

  # Allow nix to garbage collect if running out of free space during build.
  nix.settings.min-free = lib.mkDefault (100 * 1000 * 1000); # 100 MB
  nix.settings.max-free = lib.mkDefault (1000 * 1000 * 1000); # 1 GB

  # Avoid copying derivations unnecessary over SSH.
  nix.settings.builders-use-substitutes = true;

  # Write out a warning if kernel version has changed.
  system.activationScripts.requires-reboot = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        var1="`realpath /run/booted-system/{initrd,kernel,kernel-modules}`"
        var2="`realpath $systemConfig/{initrd,kernel,kernel-modules}`"

        if [[ $var1 != $var2 ]]; then
          >&2 echo "WARN: Kernel version has changed, system should be rebooted!"
        fi
      fi
    '';
  };

  # Print out a list of changed packages between current and built system.
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        echo "--- changed packages"
        ${config.nix.package}/bin/nix --extra-experimental-features nix-command store diff-closures /run/current-system "$systemConfig"
        echo "---"
      fi
    '';
  };
}
