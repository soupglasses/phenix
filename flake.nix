{
  description = "Phenix infrastructure";

  nixConfig.allow-import-from-derivation = false;
  nixConfig.extra-substituters = "https://cache.garnix.io";
  nixConfig.extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    # Utils
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    # Packages
    nix-minecraft.url = "github:imsofi/nix-minecraft/develop";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
    # Compatibility
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
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
        self.nixosModules.bad-python-server
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
        bad-python-server = import ./modules/bad-python-server.nix;
      };

      packages.${system} = import ./packages/all-packages.nix {inherit pkgs;};

      overlays = {
        packages = final: _prev: {
          phenix =
            {
              lib = import ./lib {inherit (final) pkgs;};
            }
            // final.lib.recurseIntoAttrs
            (import ./packages/all-packages.nix {inherit (final) pkgs;});
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

      # -- Library --

      legacyPackages.${system}.lib = import ./lib pkgs;

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
            self.legacyPackages."x86_64-linux".lib.deploy.activate.nixos
            self.nixosConfigurations.nona;
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

      # -- Formatter --

      formatter.${system} = pkgs.alejandra;

      # --- Tests ---

      checks.${system} = let
        deploy-checks = self.legacyPackages.${system}.lib.deploy.deployChecks self.deploy;
      in {
        deploy-activate = deploy-checks.deploy-activate;
        deploy-schema = deploy-checks.deploy-schema;

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra = {
              enable = true;
              excludes = ["-deps.nix$" "-composition.nix$"];
            };
            deadnix = {
              enable = true;
              excludes = ["-deps.nix$" "-composition.nix$"];
            };
            editorconfig-checker.enable = true;
            codespell = {
              enable = true;
              name = "codespell";
              language = "system";
              entry = "${pkgs.codespell}/bin/codespell";
              types = ["text"];
              excludes = ["-deps.nix$" "-composition.nix$"];
            };
          };
        };
      };
    });
}
