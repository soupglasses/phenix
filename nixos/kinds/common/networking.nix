{
  config,
  lib,
  ...
}: {
  # Do not log refused connections so not to spam dmesg/journalctl.
  networking.firewall.logRefusedConnections = lib.mkDefault false;

  # Use networkd for networking instead of shell scripts.
  systemd.network.enable = true;
  networking.useDHCP = false;

  # Use resolved as well if networkd is used.
  services.resolved.enable = config.systemd.network.enable;

  # Do not enable multicast by default.
  services.resolved.llmnr = lib.mkDefault "false";

  # Do not take down the network on updates, services might fail to resolve if systemd-networkd is stopped.
  # Under the hood will use `systemctl restart service` over the default `systemctl stop/start service`.
  systemd.services.systemd-networkd.stopIfChanged = false;
  systemd.services.systemd-resolved.stopIfChanged = false;
}
