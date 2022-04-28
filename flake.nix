{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-generators, utils }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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
        base = (nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            "${nixpkgs}/nixos/maintainers/scripts/openstack/openstack-image.nix"
            ./common/default.nix
          ];
          }).config.system.build.openStackImage;

        openstack = nixos-generators.nixosGenerate {
          inherit pkgs;
          modules = [
            ./common/default.nix
          ];
          format = "openstack";
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
