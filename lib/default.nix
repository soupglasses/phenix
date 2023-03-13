{
  nixpkgs,
  supportedSystems,
}: let
  eachSystem = f:
    nixpkgs.lib.genAttrs supportedSystems (system:
      f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
      });
in
  {
    mkSystem = import ./mkSystem.nix;
  }
  // eachSystem ({pkgs, ...}: {
    deploy = import ./deploy/default.nix pkgs;
  })
