{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/virtualisation/openstack-config.nix") ];
}
