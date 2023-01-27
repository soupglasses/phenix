{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # Utils
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Packages
    nix-minecraft.url = "github:imsofi/nix-minecraft/develop";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    sops-nix,
    nix-minecraft,
    ...
  } @ inputs: let
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    foldEachSystem = systems: f:
      builtins.foldl' nixpkgs.lib.recursiveUpdate {}
      (nixpkgs.lib.forEach systems f);

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
    foldEachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.pkgs;
    in {
      # --- Public ---

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      packages.${system} = {
        tt-rss-plugin-fever = pkgs.callPackage ./pkgs/tt-rss-plugin-fever.nix {};
      };

      overlays = {
        tt-rss-plugin-fever = final: _prev: {
          tt-rss-plugin-fever = final.callPackage ./pkgs/tt-rss-plugin-fever.nix {};
        };
        prometheus-systemd-exporter = _final: prev: {
          prometheus-systemd-exporter = prev.prometheus-systemd-exporter.overrideAttrs (_p: {
            patches = [
              # https://github.com/prometheus-community/systemd_exporter/pull/74
              (prev.fetchpatch {
                url = "https://github.com/prometheus-community/systemd_exporter/commit/0afc9bee009740825239df1e6ffa1713a57a5692.patch";
                sha256 = "sha256-ClrV9ZOlRruYXaeQwhWc9h88LP3Rm33Jf/dvxbqRS2I=";
              })
              (prev.fetchpatch {
                url = "https://github.com/prometheus-community/systemd_exporter/commit/47d7e92ec34303a8da471fd1c26106f606e5a150.patch";
                sha256 = "sha256-Ox9IE8LeYBflitelyZr4Ih1zSt9ggjnogj6k0qI2kx4=";
              })
            ];
          });
        };
      };

      lib.${system} = import ./lib pkgs;

      # --- Systems ---

      nixosConfigurations = {
        nona = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {inherit inputs system;};
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
            self.lib."x86_64-linux".deploy.activate.nixos
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
            })
            .config;
          format = "qcow2";
          partitionTableType = "legacy";
        };
      };

      # --- Development shell ---

      devShells.${system}.default = pkgs.mkShellNoCC {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
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

      checks.${system} = let
        deploy-checks = self.lib.${system}.deploy.deployChecks self.deploy;
      in {
        deploy-activate = deploy-checks.deploy-activate;
        deploy-schema = deploy-checks.deploy-schema;

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
            editorconfig-checker.enable = true;
            codespell = {
              enable = true;
              name = "codespell";
              language = "system";
              entry = "${pkgs.codespell}/bin/codespell";
              types = ["text"];
            };
          };
        };
      };
    });
}
