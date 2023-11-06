{
  description = "Phenix infrastructure";

  nixConfig.allow-import-from-derivation = true; # Allowed due to nixpkgs patching.
  nixConfig.extra-substituters = "https://cache.garnix.io";
  nixConfig.extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";

  inputs = {
    nixpkgs.url = "nixpkgs/bc571a7386d20d50f6a6a71c66598695237afacb";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Extra packages
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
    nix-minecraft.inputs.flake-utils.follows = "flake-utils";

    # Secret management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    # Formatting
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs-stable.follows = "nixpkgs";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Utils
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Compatibility
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-minecraft,
    sops-nix,
    pre-commit-hooks,
    treefmt-nix,
    devshell,
    ...
  }: let
    # List of system architectures that we want our flake binary outputs to support,
    # for example `outputs.packages` and `outputs.devshells`.
    # Note, this does not define architectures for the `nixosConfigurations`.
    supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    # Outputs a set of attrsets with each supported system architecture as keys.
    # Inputs common `pkgs` and `system` attributes for use by the caller.
    # This makes supporting multiple system-architectures easy.
    eachSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    # -- NixOS Configurations --
    # Holds the set of our NixOS configured servers.

    nixosConfigurations = {
      nona = self.lib.mkSystem self {
        system = "x86_64-linux";
        overlays = [
          nix-minecraft.overlay
          self.overlays.packages
          self.overlays.prometheus-systemd-exporter
        ];
        modules = [
          sops-nix.nixosModules.sops
          ./nixos/mixins/starship.nix
          ./nixos/hosts/nona
          {
            services.nextcloud.package = nixpkgs.lib.mkForce nixpkgs-unstable.legacyPackages."x86_64-linux".nextcloud27;
          }
        ];
      };
    };

    # -- NixOS Modules --
    # Modules create or modify configurable options included in a full nixos configuration.

    nixosModules = {
      minecraft-server = import ./nixos/modules/minecraft-server.nix;
      bad-python-server = import ./nixos/modules/bad-python-server.nix;
    };

    # -- Packages --
    # Exposes derivations as top level packages so others can use them.

    packages = eachSystem ({pkgs, ...}: import ./nixos/packages/top-level/all-packages.nix {inherit pkgs;});

    # -- Library --
    # Holds our various functions and derivations aiding in deploying nixos.

    lib = import ./nixos/lib {inherit (nixpkgs) lib;};

    # -- Overlays --
    # Allows modification of nixpkgs in-place, adding and modifying its functionality.

    overlays = {
      packages = final: _prev: {
        phenix =
          final.lib.recurseIntoAttrs
          (import ./nixos/packages/top-level/all-packages.nix {inherit (final) pkgs;});
      };
      prometheus-systemd-exporter = import ./nixos/overlays/prometheus-systemd-exporter.nix;
    };

    # -- Formatter --
    # Abstracts all formatting tools into one command, `nix fmt <location>`.

    formatter = eachSystem ({pkgs, ...}:
      treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
        programs.deadnix.enable = true;
      });

    # -- Development Shells --
    # Scoped environments including packages and shell-hooks to aid project development.

    devShells = eachSystem ({
      system,
      pkgs,
    }: {
      default = devshell.legacyPackages.${system}.mkShell {
        devshell = {
          startup = {
            motd = nixpkgs.lib.mkForce {text = "";};
            pre-commit = {text = self.checks.${system}.pre-commit.shellHook;};
          };
          packages = with pkgs; [
            nixUnstable
            # Deployment
            nixos-rebuild
            # Secrets management
            age
            ssh-to-age
            sops
            # Formatters
            alejandra
            deadnix
          ];
        };
      };
    });

    # -- Tests --
    # Verify locally that our nix configurations and file formatting is correct.

    checks = eachSystem ({
      system,
      pkgs,
    }: {
      pre-commit = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        excludes = ["-deps.nix$" "-composition.nix$" ".patch$"];
        hooks = {
          alejandra.enable = true;
          deadnix.enable = true;
          editorconfig-checker.enable = true;
          codespell = {
            enable = true;
            name = "codespell";
            language = "system";
            entry = "${pkgs.codespell}/bin/codespell -L anull -- ";
            types = ["text"];
          };
        };
      };
    });
  };
}
