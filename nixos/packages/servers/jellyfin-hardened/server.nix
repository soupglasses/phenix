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

  meta = with lib; {
    description = "The Free Software Media System";
    homepage = "https://jellyfin.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [imsofi];
    platforms = dotnet-runtime.meta.platforms;
  };
}
