# Updated version from: https://github.com/raphaelr/nixpkgs/blob/11e48e9490a055a24782d87bf767142b88588cc9/pkgs/build-support/dotnet/make-nuget-source/default.nix
{
  lib,
  python3,
  stdenvNoCC,
}: {
  name,
  description ? "",
  deps ? [],
}: let
  nuget-source =
    stdenvNoCC.mkDerivation {
      inherit name;

      meta.description = description;
      nativeBuildInputs = [python3];

      buildCommand = ''
        set -x

        mkdir -p $out/{lib,share}

        find -L ${lib.concatStringsSep " " deps} -name '*.nupkg' -exec cp --no-clobber '{}' $out/lib ';'

        # Generates a list of all licenses' spdx ids, if available.
        # Note that this currently ignores any license provided in plain text (e.g. "LICENSE.txt")
        python ${./extract-licenses-from-nupkgs.py} $out/lib > $out/share/licenses
      '';
    }
    // {
      # We need data from `$out` for `meta`, so we have to use overrides as to not hit infinite recursion.
      meta.licence = let
        depLicenses = lib.splitString "\n" (builtins.readFile "${nuget-source}/share/licenses");
      in (lib.flatten (lib.forEach depLicenses (
        spdx:
          lib.optionals (spdx != "") (lib.getLicenseFromSpdxId spdx)
      )));
    };
in
  nuget-source
