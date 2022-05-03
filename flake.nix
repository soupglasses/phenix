{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.utils.follows = "utils";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, deploy-rs, utils, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: { deploy-rs = deploy-rs.defaultPackage.${prev.system}; })
        ];
      };
      lib = pkgs.lib;
    in
    {
      images.${system} = {
        qemu = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
          inherit pkgs lib;
          config = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
              ./common
              ./hardware/qemu.nix
            ];
          }).config;
          format = "qcow2";
          partitionTableType = "legacy";
        };
      };

      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nona
          ];
        };
      };

      deploy.nodes.nona = {
        hostname = "nona.box.byte.surf";
        sshUser = "sofi";

        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.nona;
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.deploy-rs
          pkgs.nixpkgs-fmt
          pkgs.nixUnstable
        ];
        buildInputs = [ ];
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
    };
}
