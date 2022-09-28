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
      my-patches = [
        {
          meta.description = "matrix-synapse: 1.67.0 -> 1.68.0";
          url = "https://github.com/NixOS/nixpkgs/pull/193200.diff";
          sha256 = "sha256-bKmqe87hX1EhtmRqmqxyBoR4wIpwKg3fOrO+7ReZSzI=";
        }
      ];
      my-nixpkgs = self.lib.patchChannel nixpkgs "x86_64-linux" my-patches;
    in
    {
      overlays = {
        #  tt-rss-plugin-auth-ldap = import ./overlays/tt-rss-plugin-auth-ldap.nix;
      };

      nixosModules = {
        minecraft-server = import ./modules/minecraft-server.nix;
      };

      packages."x86_64-linux" = let pkgs = nixpkgs.legacyPackages."x86_64-linux"; in {
        tt-rss-plugin-fever = pkgs.callPackage ./pkgs/tt-rss-plugin-fever.nix { };
      };

      lib = {
        # https://github.com/NixOS/nix/issues/3920#issuecomment-681187597
        hashFileOrHashPatch = patch:
          if builtins.typeOf patch == "path"
          then builtins.hashFile "sha256" patch
          else patch.sha256;
        patchChannel = channel: system: patches:
          if patches == [ ] then channel else
          channel.legacyPackages.${system}.applyPatches {
            name = "nixpkgs-patched";
            src = channel;
            patches = map
              (p:
                if builtins.typeOf p == "path"
                then p
                else nixpkgs.legacyPackages.${system}.fetchpatch p)
              patches;
            postPatch = ''
              patch=$(printf '%s\n' ${builtins.concatStringsSep " "
                (map self.lib.hashFileOrHashPatch patches)} |
                sort | sha256sum | cut -c -7)
              echo "+patch-$patch" > .version-suffix
            '';
          };

        createMachineWith = channel: machineConfig:
          nixpkgs.lib.nixosSystem rec {
            system = machineConfig.system;
            modules = machineConfig.modules ++ [
              ({ pkgs, ... }: {
                _module.args = { inherit system inputs; } // (machineConfig.extraArgs or { });
                nixpkgs.pkgs = import channel ({ inherit system; }
                  // (if (machineConfig ? nixpkgs) then machineConfig.nixpkgs else { }));
                # Skip compiling nixos related docs, as patched nixpkgs makes this step excruciatingly slow.
                documentation.nixos.enable = false;
                nixpkgs.overlays =
                  (if (self ? overlays) then nixpkgs.lib.attrValues self.overlays else [ ])
                    ++ (if (machineConfig ? overlays) then machineConfig.overlays else [ ]);

                system.nixos.versionSuffix = nixpkgs.lib.mkForce ".${
                nixpkgs.lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified)}.${
                inputs.self.shortRev or "dirty"}";
                #system.nixos.revision = nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
                #nix.registry.nixpkgs.flake = nixpkgs;
                #nix.package = pkgs.nixFlakes;
                #nix.extraOptions = "experimental-features = nix-command flakes";
                #system.configurationRevision = nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
              })
            ];
          };
      };

      nixosConfigurations = {
        nona = self.lib.createMachineWith my-nixpkgs {
          system = "x86_64-linux";
          nixpkgs = { config.allowUnfree = true; };
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
