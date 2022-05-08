{ config, lib, pkgs, ... }:
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  environment.etc."cni/net.d/88-podnetwork.conflist".source = pkgs.writeText "88-podnetwork.conflist" (builtins.toJSON {
    cniVersion = "0.4.0";
    name = "podnetwork";
    plugins = [
      {
        type = "bridge";
        bridge = "cni-podman3";
        isGateway = true;
        isMasq = true;
        hairpinMode = true;
        ipam = {
          type = "host-local";
          routes = [
            { dst = "0.0.0.0/0"; }
          ];
          ranges = [
            [
              {
                subnet = "10.89.1.0/24";
                gateway = "10.89.1.1";
              }
            ]
          ];
        };
      }
      {
        type = "portmap";
        capabilities = { portMappings = true; };
      }
      {
        type = "firewall";
      }
      {
        type = "tuning";
      }
    ];
  });
}
