{lib, ...}: {
  imports = [
    ../common
  ];

  # Internationaliation.
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Etc/UTC";

  # Print URLs instead of opening them.
  environment.variables.BROWSER = "echo";

  # Use neovim as the editor by default.
  programs.vim.defaultEditor = lib.mkDefault true;

  # Attempt to find hostname through dhcp/cloud-init by default.
  networking.hostName = lib.mkDefault "";

  # Enable firewall on public facing servers.
  networking.firewall.enable = true;

  # Allow PMTU / DHCP to servers.
  networking.firewall.allowPing = true;

  # Only users in the wheel group should have access to the sudo binary.
  security.sudo.execWheelOnly = true;

  # Do not require a password for sudo for users in the wheel group.
  security.sudo.wheelNeedsPassword = false;

  # Enable SSH to allow remote control.
  services.openssh.enable = true;
  services.openssh.openFirewall = true;

  # Only allow authorized keys to be managed by the system itself.
  services.openssh.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];

  # Servers do not typically need sound or fonts.
  fonts.fontconfig.enable = lib.mkDefault false;
  sound.enable = false;

  # No mutable users on a server.
  users.mutableUsers = false;

  # Automatically garbage collect old nix store derivations.
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 14d";

  # Machine should reboot instead of waiting for an operator when encountering a problem.
  boot.kernelParams = ["panic=1" "boot.panic_on_fail"];

  # Servers are headless and there is no operator locally to access emergency mode.
  # Continue to attempt booting and hope we can get access remotely.
  systemd.enableEmergencyMode = false;

  # Shorten watchdog timers to get hung machines to come back faster.
  systemd.watchdog.runtimeTime = "20s";
  systemd.watchdog.rebootTime = "30s";

  # Do not allow a server to suspend or hibernate.
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
  '';

  # Use Google's Congestion Control Algorithm BBR.
  # Improves network throughput and latency significantly.
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
