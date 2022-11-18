{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nix-minecraft.url = "github:imsofi/nix-minecraft/develop";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix, pre-commit-hooks, nix-minecraft, ... }@inputs:
    let
      commonModule = {
        # Helps error message know where this module is defined, avoiding `<unknown-file>` in errors.
        _file = ./flake.nix;
        imports = [
          sops-nix.nixosModules.sops
        ];
        config = {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = nixpkgs.lib.attrValues self.overlays ++ [
            nix-minecraft.overlays.default
          ];
          # Follow this git repo's hashes and last modified date for version suffixes, instead of
          # using upstream nixpkgs.
          system.nixos.versionSuffix = nixpkgs.lib.mkForce ".${
            nixpkgs.lib.substring 0 8 (self.lastModifiedDate or self.lastModified)}.${
            self.shortRev or "dirty"}";
          # WORKAROUND: Nix struggles with revisions in dirty repos -> https://github.com/NixOS/nix/pull/5385
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        };
      };
    in
    {
      overlays = {
        #  tt-rss-plugin-auth-ldap = import ./overlays/tt-rss-plugin-auth-ldap.nix;
        tt-rss-plugin-fever = (final: prev: {
          tt-rss-plugin-fever = final.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
        });
      };

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      packages."x86_64-linux" = let pkgs = nixpkgs.legacyPackages."x86_64-linux"; in {
        tt-rss-plugin-fever = pkgs.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
      };

      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs system; };
          modules = [
            commonModule
            ./hosts/nona
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
          inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
          nativeBuildInputs = with pkgs; [
            # Basic packages
            nixUnstable
            pkgs.deploy-rs
            # sops-nix related
            age
            ssh-to-age
            sops
          ];
        });

      checks.x86_64-linux =
        let
          # TODO: Redo this to allow for multi architecture checks.
          deploy-checks = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;
        in
        {
          deploy-schema = deploy-checks.schema;
          deploy-activate = deploy-checks.activate;

          pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
            src = ./.;
            hooks = with nixpkgs.legacyPackages.x86_64-linux; {
              nixpkgs-fmt.enable = true;
              editorconfig-checker = {
                enable = true;
                name = "editorconfig-checker";
                entry = "${pkgs.editorconfig-checker}/bin/editorconfig-checker";
                language = "system";
                types = [ "text" ];
              };
              codespell = {
                name = "codespell";
                language = "system";
                entry = "${pkgs.codespell}/bin/codespell";
                types = [ "text" ];
              };
            };
          };
        };
    };
}
