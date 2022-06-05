{ config, lib, pkgs, ... }:
{
  imports = [ ./users.nix ];

  boot.cleanTmpDir = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Etc/UTC";

  # NOTE: If you attempt to change the default password
  # below, there is a bug where it may corrupt the /etc/shadow
  # file. See : https://github.com/NixOS/nixpkgs/issues/99433
  # WORKAROUND: Enable mutableUsers, remove the root password
  # entry while logged in as root. Use `pwck -q` to fix any issues.
  # Then attempt to disable mutableUsers when deploying the new
  # password.
  users.mutableUsers = lib.mkDefault true;
  users.users."root".password = lib.mkDefault "phenix";

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
  environment.systemPackages = with pkgs; [
    comma
    git
    htop
    neofetch
    neovim
  ];

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

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  nix = {
    package = pkgs.nixUnstable;
    gc = { automatic = true; dates = "weekly"; };
    settings = {
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
  };

  networking.firewall = {
    enable = lib.mkDefault true;
  };
}
