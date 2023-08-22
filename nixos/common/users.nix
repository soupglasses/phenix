{pkgs, ...}: {
  programs.zsh.enable = true;
  users.users.sofi = {
    isNormalUser = true;
    useDefaultShell = false;
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEflwI90G6tmsr4oI/UW6YNKh7OL0cv396DvdNht7von"];
  };
}
