{
  lib,
  fetchFromGitHub,
  nixosTests,
  dotnetCorePackages,
  buildDotnetModule,
  ffmpeg,
  fontconfig,
  freetype,
  jellyfin-web,
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

  projectFile = "Jellyfin.Server/Jellyfin.Server.csproj";
  executables = ["jellyfin"];

  nugetDeps = ./nuget-deps.nix;
  packNupkg = false;

  runtimeDeps = [
    ffmpeg
    fontconfig
    freetype
  ];
  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;
  dotnetBuildFlags = ["--no-self-contained"];

  preInstall = ''
    makeWrapperArgs+=(
      --add-flags "--ffmpeg ${ffmpeg}/bin/ffmpeg"
      --add-flags "--webdir ${jellyfin-web}/share/jellyfin-web"
    )
  '';

  passthru.tests = {
    smoke-test = nixosTests.jellyfin;
  };

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "The Free Software Media System";
    homepage = "https://jellyfin.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [imsofi];
    platforms = dotnet-runtime.meta.platforms;
  };
}
