{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  phenix.users = {
    groups = mkOption {
      type = types.listOf types.str;
      default = ["wheel"];
      example = ''[ "wheel" "libvirtd" "docker "]'';
      description = "The groups that staff users should be assigned to";
    };

    shell = mkOption {
      type = types.package;
      default = pkgs.bashInteractive;
      example = "pkgs.powershell";
      description = "The default shell that staff users will be given by default.";
    };
  };

  cfg = config.phenix.users;

  mkUser = {
    keys,
    shell ? cfg.shell,
    extraGroups ? cfg.groups,
    ...
  }: {
    isNormalUser = true;
    inherit extraGroups shell;
    openssh.authorizedKeys = {
      inherit keys;
    };
  };
in {
  options.phenix.users = phenix.users;

  config.users.users = {
    sofi = mkUser {
      keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEflwI90G6tmsr4oI/UW6YNKh7OL0cv396DvdNht7von"];
    };
  };

  config.users.users.root.openssh.authorizedKeys.keys = config.users.users.sofi.openssh.authorizedKeys.keys;
}
