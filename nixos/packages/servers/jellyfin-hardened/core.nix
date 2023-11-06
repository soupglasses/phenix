{
  lib,
  fetchFromGitHub,
  dotnetCorePackages,
  buildDotnetModule,
  sqlite,
}:
buildDotnetModule rec {
  pname = "jellyfin";
  version = "10.8.10"; # ensure that jellyfin-web has matching version

  src = fetchFromGitHub {
    owner = "GermanCoding";
    repo = "jellyfin";
    rev = "e4920ad771bb598568aa045aa6ca78833c985710";
    hash = "sha256-o+SeD/KyY4Sxg5+OX9RX3cD08EG9M6iDrpdp0gteaVI=";
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
    "MediaBrowser.Common/MediaBrowser.Common.csproj" # Jellyfin.Common
    "MediaBrowser.Controller/MediaBrowser.Controller.csproj" # Jellyfin.Controller
    "Jellyfin.Data/Jellyfin.Data.csproj" # Jellyfin.Data
    "src/Jellyfin.Extensions/Jellyfin.Extensions.csproj" # Jellyfin.Extensions
    "MediaBrowser.Model/MediaBrowser.Model.csproj" # Jellyfin.Model
    "Emby.Naming/Emby.Naming.csproj" # Jellyfin.Naming
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
    broken = true;
  };
}
