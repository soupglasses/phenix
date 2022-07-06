{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.tt-rss-plugin-auth-ldap
        ];
      };
      lib = pkgs.lib;
    in
    {
      overlays = {
        tt-rss-plugin-auth-ldap = import ./overlays/tt-rss-plugin-auth-ldap.nix;
      };

      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit pkgs;
          modules = [
            ./hosts/nona
            sops-nix.nixosModules.sops
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

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          # Basic packages
          pkgs.nixUnstable
          # Testing packages
          pkgs.codespell
          pkgs.editorconfig-checker
          pkgs.nixpkgs-fmt
          pkgs.pre-commit
          # deploy-rs related
          deploy-rs.defaultPackage.${system}
          # sops-nix related
          pkgs.age
          pkgs.ssh-to-age
          pkgs.sops
        ];
        buildInputs = [ ];
      };

      # This is highly advised, and will prevent many possible mistakes
      checks.${system} = deploy-rs.lib.${system}.deployChecks self.deploy;
    };
}
