{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
		htop
    neofetch
    neovim
  ];

  networking.hostName = "nona";
  networking.domain = "box.byte.surf";
}
