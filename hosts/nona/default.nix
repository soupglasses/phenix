{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neofetch
    neovim
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";
}
