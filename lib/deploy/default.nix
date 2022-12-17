# Taken from https://github.com/serokell/deploy-rs/blob/master/flake.nix
# Original code licenced under MPL v2.0, Serokell & Contributors.
pkgs: rec {
  activate = rec {
    custom = {
      __functor = customSelf: base: activate:
        pkgs.buildEnv {
          name = "activatable-" + base.name;
          paths = [
            base
            (pkgs.writeTextFile {
              name = base.name + "-activate-path";
              text = ''
                #!${pkgs.runtimeShell}
                set -euo pipefail
                if [[ "''${DRY_ACTIVATE:-}" == "1" ]]
                then
                    ${customSelf.dryActivate or "echo ${pkgs.writeScript "activate" activate}"}
                else
                    ${activate}
                fi
              '';
              executable = true;
              destination = "/deploy-rs-activate";
            })
            (pkgs.writeTextFile {
              name = base.name + "-activate-rs";
              text = ''
                #!${pkgs.runtimeShell}
                exec ${pkgs.deploy-rs}/bin/activate "$@"
              '';
              executable = true;
              destination = "/activate-rs";
            })
          ];
        };
    };

    nixos = base:
      (custom // {dryActivate = "$PROFILE/bin/switch-to-configuration dry-activate";}) base.config.system.build.toplevel ''
        # work around https://github.com/NixOS/nixpkgs/issues/73404
        cd /tmp
        $PROFILE/bin/switch-to-configuration switch
        # https://github.com/serokell/deploy-rs/issues/31
        ${with base.config.boot.loader;
          pkgs.lib.optionalString systemd-boot.enable
          "sed -i '/^default /d' ${efi.efiSysMountPoint}/loader/loader.conf"}
      '';

    home-manager = base: custom base.activationPackage "$PROFILE/activate";

    noop = base: custom base ":";
  };

  deployChecks = deploy:
    builtins.mapAttrs (_: check: check deploy) {
      deploy-schema = deploy:
        pkgs.runCommand "jsonschema-deploy-system" {} ''
          ${pkgs.python3.pkgs.jsonschema}/bin/jsonschema -i ${pkgs.writeText "deploy.json" (builtins.toJSON deploy)} ${./interface.json} && touch $out
        '';

      deploy-activate = deploy: let
        profiles = builtins.concatLists (pkgs.lib.mapAttrsToList (nodeName: node: pkgs.lib.mapAttrsToList (profileName: profile: [(toString profile.path) nodeName profileName]) node.profiles) deploy.nodes);
      in
        pkgs.runCommand "deploy-rs-check-activate" {} ''
          for x in ${builtins.concatStringsSep " " (map (p: builtins.concatStringsSep ":" p) profiles)}; do
            profile_path=$(echo $x | cut -f1 -d:)
            node_name=$(echo $x | cut -f2 -d:)
            profile_name=$(echo $x | cut -f3 -d:)
            test -f "$profile_path/deploy-rs-activate" || (echo "#$node_name.$profile_name is missing the deploy-rs-activate activation script" && exit 1);
            test -f "$profile_path/activate-rs" || (echo "#$node_name.$profile_name is missing the activate-rs activation script" && exit 1);
          done
          touch $out
        '';
    };
}
