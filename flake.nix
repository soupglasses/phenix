{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-minecraft.url = "github:Infinidoge/nix-minecraft/refactor/fu";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix, nix-minecraft, ... }@inputs:
    let
      commonModule = {
        # Helps error message know where this module is defined, avoiding `<unknown-file>` in errors.
        _file = ./flake.nix;
        config = {
          nixpkgs.overlays = nixpkgs.lib.attrValues self.overlays;
        };
      };
    in
    {
      overlays = {
        tt-rss-plugin-auth-ldap = import ./overlays/tt-rss-plugin-auth-ldap.nix;
      };

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit system inputs; };
          modules = [
            self.nixosModules.minecraft-server
            commonModule
            ./hosts/nona
            sops-nix.nixosModules.sops
          ];
        };
      };

      deploy.nodes.nona = {
        hostname = "nona.hosts.byte.surf";
        sshUser = "sofi";

        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.nona;
        };
      };

      images.x86_64-linux = {
        qemu = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
          system = "x86_64-linux";
          config = (nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              commonModule
              "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
              ./common
              ./common/hardware/qemu.nix
            ];
          }).config;
          format = "qcow2";
          partitionTableType = "legacy";
        };
      };

      devShells.x86_64-linux.default =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in (pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Basic packages
            nixUnstable
            pkgs.deploy-rs
            # Testing packages
            codespell
            editorconfig-checker
            nixpkgs-fmt
            pre-commit
            # sops-nix related
            age
            ssh-to-age
            sops
          ];
        });

      # This is highly advised, and will prevent many possible mistakes
      checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;
    };
}
