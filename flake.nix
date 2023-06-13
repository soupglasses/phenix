{
  description = "Phenix infrastructure";

  nixConfig.allow-import-from-derivation = false;
  nixConfig.extra-substituters = "https://cache.garnix.io";
  nixConfig.extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    # Packages
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
    nix-minecraft.inputs.flake-utils.follows = "flake-utils";
    # Secret management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    # Formatting
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
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
    nix-minecraft,
    sops-nix,
    pre-commit-hooks,
    treefmt-nix,
    devshell,
    ...
  }: let
    supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    eachSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (import ./nixos/overlays/make-nuget-source-recursive.nix)
            ];
          };
        });
  in {
    # -- NixOS Configurations --
    # Holds the set of our NixOS configured servers.

    nixosConfigurations = {
      nona = self.lib.mkSystem self {
        system = "x86_64-linux";
        imports = [
          sops-nix.nixosModules.sops
          self.nixosModules.bad-python-server
        ];
        overlays = [
          nix-minecraft.overlay
          self.overlays.packages
          self.overlays.prometheus-systemd-exporter
        ];
        modules = [
          ./nixos/hosts/nona
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
    # Exposes our packages as a flake output so others can use them.

    packages = eachSystem ({pkgs, ...}: import ./nixos/packages/top-level/all-packages.nix {inherit pkgs;});

    # -- Library --
    # Holds our various functions and derivations aiding in deploying nixos.

    lib = import ./nixos/lib/default.nix // eachSystem ({pkgs, ...}: import ./nixos/lib/with-pkgs.nix pkgs);

    # -- Overlays --
    # Allows modification of nixpkgs in-place, adding and modifying its functionality.

    overlays = {
      packages = final: _prev: {
        phenix =
          final.lib.recurseIntoAttrs
          (import ./nixos/packages/top-level/all-packages.nix {inherit (final) pkgs;});
      };
      prometheus-systemd-exporter = import ./nixos/overlays/prometheus-systemd-exporter.nix;
      tt-rss-plugin-auth-ldap = import ./nixos/overlays/tt-rss-plugin-auth-ldap.nix;
    };

    # -- Formatter --
    # Abstracts all formatting tools into one command, `nix fmt`.

    formatter = eachSystem ({pkgs, ...}:
      treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
        programs.deadnix.enable = true;
        programs.terraform.enable = true;
      });

    # -- Development Shells --
    # Virtual shells holding packages and shellhooks aiding development.

    devShells = eachSystem ({
      system,
      pkgs,
    }: {
      default = devshell.legacyPackages.${system}.mkShell {
        devshell = {
          startup = {
            motd = nixpkgs.lib.mkForce {text = "";};
            pre-commit-check = {text = self.checks.${system}.pre-commit-check.shellHook;};
          };
          packages = with pkgs; [
            nixUnstable
            # Deployment
            terraform
            # Secrets management
            age
            ssh-to-age
            sops
            # Formatters
            alejandra
          ];
        };
      };
    });

    # -- Tests --
    # Verify locally that nixos configurations and file formatting is correct.

    checks = eachSystem ({
      system,
      pkgs,
    }: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
