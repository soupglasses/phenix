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
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
    in
    {
      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./common
            ./hardware/qemu.nix
            ./hosts/nona
          ];
        };
      };

      images = {
        netcup = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
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

      devShell.${system} = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          nixpkgs-fmt
          nixUnstable
        ];
        buildInputs = [ ];
      };

      deploy.nodes.nona = {
        hostname = "nona.box.byte.surf";
        sshUser = "root";

        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.nona;
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
    };
}
