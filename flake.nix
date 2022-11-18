{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # Utils
    deploy-rs.url = "github:serokell/deploy-rs";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Packages
    nix-minecraft.url = "github:imsofi/nix-minecraft/develop";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , deploy-rs
    , pre-commit-hooks
    , sops-nix
    , nix-minecraft
    , ...
    } @ inputs:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      foldEachSystem = systems: f:
        builtins.foldl' nixpkgs.lib.recursiveUpdate { } (nixpkgs.lib.forEach systems f);

      commonModule = {
        _file = ./flake.nix;
        imports = [
          sops-nix.nixosModules.sops
        ];
        config = {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays =
            nixpkgs.lib.attrValues self.overlays
            ++ [
              nix-minecraft.overlays.default
            ];
          # Use our hashes and modified dates for version
          # suffixes, instead of upstream.
          system.nixos.versionSuffix =
            nixpkgs.lib.mkForce ".${
            nixpkgs.lib.substring 0 8 (self.lastModifiedDate or self.lastModified)
          }.${
            self.shortRev or "dirty"
          }";
          # Nix struggles with revisions in dirty repos
          # See: https://github.com/NixOS/nix/pull/5385
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        };
      };
    in
    foldEachSystem systems (system:
    let
      pkgs = nixpkgs.legacyPackages.${system}.pkgs;
    in
    {
      # --- Public ---

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      packages.${system} = {
        tt-rss-plugin-fever = pkgs.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
      };

      overlays = {
        tt-rss-plugin-fever = final: prev: {
          tt-rss-plugin-fever = final.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
        };
      };

      # --- Systems ---

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
          path =
            deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.nona;
        };
      };

      # --- System images ---

      images."x86_64-linux" = {
        qemu = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
          system = "x86_64-linux";
          config =
            (nixpkgs.lib.nixosSystem {
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

      # --- Development shell ---

      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
        nativeBuildInputs = with pkgs; [
          # Basic Packages
          nixUnstable
          pkgs.deploy-rs
          # Secret Encryption
          age
          ssh-to-age
          sops
          # Helpers and formatters
          alejandra
        ];
      };

      # --- Tests ---

      checks.${system} =
        let
          deploy-checks = deploy-rs.lib.${system}.deployChecks self.deploy;
        in
        {
          deploy-activate = deploy-checks.activate;
          deploy-schema = deploy-checks.schema;

          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
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
    });
}
