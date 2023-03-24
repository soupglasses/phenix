{
  lib,
  fetchFromGitHub,
  dotnetCorePackages,
  buildDotnetModule,
  sqlite,
}:
buildDotnetModule rec {
  pname = "jellyfin";
  version = "10.8.8"; # ensure that jellyfin-web has matching version

  src = fetchFromGitHub {
    owner = "GermanCoding";
    repo = "jellyfin";
    rev = "4c06968a00c9ee339765cabd3918621691e13212";
    hash = "sha256-6vpXJsfUgbn7j9wK3FS/pBw/7uRzkOIu83jo8VBwEE8=";
  };

  patches = [
    # when building some warnings are reported as error and fail the build.
    ./disable-warnings.patch
    ./extra-disable.patch
  ];

  propagatedBuildInputs = [
    sqlite
  ];

  projectFile = [
    "MediaBrowser.Controller/MediaBrowser.Controller.csproj" # Jellyfin.Controller
    "Emby.Naming/Emby.Naming.csproj" # Jellyfin.Naming
    "MediaBrowser.Common/MediaBrowser.Common.csproj" # Jellyfin.Common
    "MediaBrowser.Model/MediaBrowser.Model.csproj" # Jellyfin.Model
    "Jellyfin.Data/Jellyfin.Data.csproj" # Jellyfin.Data
    "src/Jellyfin.Extensions/Jellyfin.Extensions.csproj" # Jellyfin.Extensions
  ];

  nugetDeps = ./nuget-deps.nix;
  packNupkg = true;

  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;
  dotnetBuildFlags = ["--no-self-contained"];

  meta = with lib; {
    description = "The Free Software Media System";
    homepage = "https://jellyfin.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [imsofi];
    platforms = dotnet-runtime.meta.platforms;
  };
}
