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
      lib = pkgs.lib;
    in {
      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware/netcup.nix
            ./common/default.nix
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
              ./hardware/netcup.nix
              ./common/default.nix
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
    };
}
