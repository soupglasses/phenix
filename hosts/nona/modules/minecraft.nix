{ config, pkgs, lib, inputs, ... }:
{
  services.minecraft-server = {
    enable = true;
    declarative = false;
    eula = true;
    dataDir = "/var/lib/minecraft/sofrob";
    openFirewall = true;
    package = inputs.nix-minecraft.packages.${pkgs.system}.fabricServers.fabric-1_19;
    jvmOpts = "-Xmx2048M -Xms2048M";
  };
}
