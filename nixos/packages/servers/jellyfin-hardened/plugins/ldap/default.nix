{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  jellyfin-core,
}:
buildDotnetModule rec {
  pname = "jellyfin-plugin-ldapauth";
  version = "17";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-plugin-ldapauth";
    rev = "v${version}";
    hash = "sha256-jOhINvR6o/RtqMQ7gkUgXVQgcqlz0SasOKIxGho7qls=";
  };

  patches = [
    ./0001-Use-new-changePassword-interface.patch
    ./0002-Disable-warning-as-errors.patch
  ];

  projectFile = "LDAP-Auth/LDAP-Auth.csproj";
  nugetDeps = ./nuget-deps.nix;
  packNupkg = false;

  projectReferences = [
    jellyfin-core
    jellyfin-core.nuget-source
  ];

  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;

  meta.broken = true;
}
