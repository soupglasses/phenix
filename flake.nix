{
  inputs = {
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, impermanence, nixpkgs, nixos-generators, utils }:
    utils.lib.eachSystem [ "x86_64-linux" ] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        openstack = nixos-generators.nixosGenerate {
          pkgs = pkgs;
          modules = [
            impermanence.nixosModules.impermanence
            ./common/default.nix
          ];
          format = "openstack";
        };
      };

      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [ ];
      };
    });
}
