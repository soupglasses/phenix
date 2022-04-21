{ config, lib, pkgs, ... }:

{
  imports = [ ./paranoid.nix ./users.nix ];

  phenix.paranoid.enable = true;

  nix = {
    autoOptimiseStore = true;
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvgn0kSAboULv37yLS1fGwByGSudhbQGrP/RrO7+cH+"
  ];

  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"
  ];

  security.sudo.execWheelOnly = true;
  environment.defaultPackages = lib.mkForce [];

  services.openssh = {
    passwordAuthentication = false;
    openFirewall = true;
    kbdInteractiveAuthentication = false;
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
      '';
  };

  networking.firewall = {
    enable = true;
  };

}
