{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  jellyfin-hardened-core,
}:
buildDotnetModule {
  pname = "jellyfin-plugin-ldapauth";
  version = "16";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-plugin-ldapauth";
    rev = "3a5b07b4d393798170d460f776b3f515cc1a5f86";
    hash = "sha256-bM2sn77mIavUSk7dhgr6le6CX0HbTpTM9KR6EVohbw8=";
  };

  patches = [
    ./0001-use-new-ChangePassword-interface.patch
  ];

  projectFile = "LDAP-Auth.sln";
  nugetDeps = ./nuget-deps.nix;
  packNupkg = false;

  projectReferences = [jellyfin-hardened-core];

  dotnet-sdk = dotnetCorePackages.sdk_6_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_6_0;
}
