{...}: let
  flake-lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  flake-compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${flake-lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.flake-compat.locked.narHash;
  };
  self = import flake-compat {src = ./.;};
  packages = self.defaultNix.outputs.packages.${builtins.currentSystem};
in
  packages
  // self.defaultNix
