{ config, lib, pkgs, ... }:

{
  imports = [ ./users.nix ];

  nix = {
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Etc/UTC";

  #security.auditd.enable = true;
  #security.audit.enable = true;
  #security.audit.rules = [
  #  "-a exit,always -F arch=b64 -S execve"
  #];

  security.sudo.execWheelOnly = true;
  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.defaultPackages = lib.mkForce [ ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "prohibit-password";
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
