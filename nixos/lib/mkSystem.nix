# Our reimplementation of Nixpkgs's `lib.nixosSystem` function:
# https://github.com/NixOS/nixpkgs/blob/a14013769370b021e23200e7199d8cfaeb97098a/flake.nix#L21-L36
#
# This reimplementation adds extra features:
# * Adds a `nixpkgs` argument to allow you to define your nixpkgs source.
# * Adds a `patches` argument to allow patching nixpkgs.
# * Adds an `overlays` argument as an alias for configuring `nixpkgs.overlays`.
# * Enables `nixpkgs.config.allowUnfree` by default.
{lib}: (
  self: {
    # Allow `system` to alternatively be defined from inside the module. This breaks patching!
    system ? null,
    nixpkgs ? self.inputs.nixpkgs,
    patches ? [],
    modules ? [],
    overlays ? [],
    extraArgs ? {},
  }: let
    nixpkgs' =
      if patches != []
      then
        if system == null
        then abort "Cannot patch nixpkgs without the `system` argument being defined. It is required for IFD."
        else
          # Here be dragons. Uses Import From Derivation (IFD): https://nixos.wiki/wiki/Import_From_Derivation
          (import nixpkgs {inherit system;}).applyPatches {
            name = "nixpkgs-patched";
            src = nixpkgs;
            inherit patches;
          }
      else nixpkgs;
  in
    import "${builtins.toString nixpkgs'}/nixos/lib/eval-config.nix" {
      inherit system;
      modules =
        modules
        ++ [
          {
            # I am not sure why `extraArgs` got deprecated for `_module.args`.
            _module.args = extraArgs;

            # TODO: Rework this into a module using allowUnfreePredicate.
            nixpkgs.config.allowUnfree = true;

            nixpkgs.overlays = overlays;

            # Add hashes and dates from our flake to the NixOS version, easily see the status
            # of a machine with `nixos-version`.
            system.nixos.versionSuffix =
              lib.mkForce ".${
                lib.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")
              }.${
                self.shortRev or "dirty"
              }";
            system.nixos.revision = lib.mkIf (self ? rev) self.rev;
          }
        ];
    }
)
