{
  inputs = {
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, impermanence, nixpkgs, nixos-generators, utils }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        karius = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            impermanence.nixosModules.impermanence
            ./common/hardware/openstack.nix
            ./common/default.nix
          ];
        };
      };

      packages.${system} = {
        base = import "./images/make-image.nix" {
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
          config = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./images/openstack.nix
            ];
          }).config;
          format = "qcow2";
          diskSize = 8192;
          name = "openstack";
        };

        openstack = nixos-generators.nixosGenerate {
          pkgs = pkgs;
          modules = [
            impermanence.nixosModules.impermanence
            ./common/default.nix
          ];
          format = "iso";
        };
      };

      devShell.${system} = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [ ];
      };
    };
}
