{
  lib,
  pkgs,
  ...
}: {
  imports = [./users.nix];

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
  security.sudo.extraRules = [
    {
      groups = ["wheel"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowAgentForwarding = false;
      AllowStreamLocalForwarding = false;
      AllowTcpForwarding = true;
      AuthenticationMethods = "publickey";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  nix = {
    package = pkgs.nixUnstable;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      allowed-users = ["@wheel"];
      trusted-users = ["@wheel"]; # Needed because of: https://github.com/NixOS/nix/issues/2127
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;

      builders-use-substitutes = true;
      substituters = ["https://nix-community.cachix.org" "https://cache.garnix.io"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };

  networking.firewall = {
    enable = true;
    logRefusedConnections = false;
  };

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  environment.defaultPackages = lib.mkForce [];
  environment.systemPackages = with pkgs; [
    # Management
    curl
    fd
    git
    htop
    moreutils # provides: vidir, etc.
    neofetch
    neovim
    openssl
    psmisc # provides: killall, pstree, etc.
    ripgrep # provides: rg
    rsync
    tree
    wget

    # Compression & De-compression
    atool # provides: apack, aunpack, acat, etc.
    bzip2
    gnutar # provides: tar
    gzip
    lz4
    lzip
    p7zip # provides: 7z
    xz
    zip
    unzip
    zstd

    # Data formatters
    libxml2 # provides: xmllint
    jq
    yq

    # Networking
    iperf
    nmap

    # Hardware
    ethtool
    lshw
    lsof
    pciutils # provides: lspci
    smartmontools # provides: smartctl, etc.
    usbutils # provides: lsusb
  ];
}