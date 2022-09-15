{
  description = "Phenix infrastructure";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-minecraft.url = "github:imsofi/nix-minecraft/develop";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix, nix-minecraft, ... }@inputs:
    let
      localPatches = [ ];
      remotePatches = [
        {
          meta.description = "tt-rss-plugin-auth-ldap: fix ldaps connection issue";
          url = "https://github.com/NixOS/nixpkgs/pull/179923.diff";
          sha256 = "sha256-ugW6pbFp5M6EfKB9rmzEWKeEUr5ibs2891+flywVMmU=";
        }
      ];
      my-nixpkgs = self.lib.patchChannel "x86_64-linux" nixpkgs localPatches remotePatches;
    in
    {
      overlays = {
        tt-rss-plugin-auth-ldap = import ./overlays/tt-rss-plugin-auth-ldap.nix;
      };

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      packages."x86_64-linux" = let pkgs = nixpkgs.legacyPackages."x86_64-linux"; in {
        tt-rss-plugin-fever = pkgs.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
      };

      lib = {
        # https://github.com/NixOS/nix/issues/3920#issuecomment-681187597
        patchChannel = system: channel: localPatches: remotePatches:
          if localPatches ++ remotePatches == [ ] then channel else
          nixpkgs.legacyPackages.${system}.applyPatches {
            name = "nixpkgs-patched";
            src = channel;
            patches = localPatches ++ map nixpkgs.legacyPackages.${system}.fetchpatch remotePatches;
            postPatch = ''
              patch=$(printf '%s\n' ${builtins.concatStringsSep " "
                (localPatches ++ map (patch: patch.sha256) remotePatches)} |
                sort | sha256sum | cut -c -7)
              echo "+patch-$patch" > .version-suffix
            '';
          };

        createMachineWith = channel: machineConfig:
          import (channel + "/nixos/lib/eval-config.nix") {
            system = if (machineConfig ? system) then machineConfig.system else channel.hostPlatform.system;
            modules = machineConfig.modules ++ [
              ({ pkgs, ... }: {
                _module.args = { inherit inputs; } // (machineConfig.extraArgs or { });
                system.nixos.versionSuffix = ".${
                nixpkgs.lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified)}.${
                inputs.self.shortRev or "dirty"}";
                system.nixos.revision = nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
                #nix.registry.nixpkgs.flake = nixpkgs;
                #nix.package = pkgs.nixFlakes;
                #nix.extraOptions = "experimental-features = nix-command flakes";
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = (nixpkgs.lib.attrValues self.overlays) ++ machineConfig.overlays;
                system.configurationRevision = nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
              })
            ];
          };
      };

      nixosConfigurations = {
        nona = self.lib.createMachineWith my-nixpkgs {
          system = "x86_64-linux";
          overlays = [ nix-minecraft.overlays.default ];
          modules = [
            self.nixosModules.minecraft-server
            sops-nix.nixosModules.sops
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
