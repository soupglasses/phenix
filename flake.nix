{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations = {
        karius = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./common/default.nix
          ];
        };
      };

      packages.${system} = {
        openstack = (nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            "${nixpkgs}/nixos/maintainers/scripts/openstack/openstack-image-zfs.nix"
            ./common/default.nix
          ];
        }).config.system.build.openstackImage;
      };

      devShell.${system} = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          nixpkgs-fmt
          nixUnstable
        ];
        buildInputs = [ ];
      };
    };
}
