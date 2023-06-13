{
  lib,
  fetchFromGitea,
  php82,
  dataDir ? "/var/lib/kbin",
}: let
  phpDrv = php82.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled
      ++ (with all; [
        amqp
        redis
      ]);
  };
in
  php82.buildComposerProject (_finalAttrs: {
    pname = "kbin-core";
    version = "0.0.1-b20230613";

    src = fetchFromGitea {
      domain = "codeberg.org";
      owner = "Kbin";
      repo = "kbin-core";
      rev = "07f6976d41a8b28802bd3f5bc21c2e8f41a83c6d";
      hash = "sha256-fw7IXo57UbNb0nmfmpANamWII5FncGTsriLevFN4bbM=";
    };

    patches = [
      ./0001-Fix-to-allow-strict-composer-validation.patch
    ];

    php = phpDrv;
    composer = phpDrv.packages.composer;

    vendorHash = "sha256-urlT3ZssXuqFc7ZlYmPRBKbAQL+PoPLmaVgMDzgt8/w=";

    postInstall = ''
      ln -s ${dataDir}/.env $out/share/php/kbin-core/.env
    '';

    meta = with lib; {
      description = "Decentralized content aggregator and microblogging platform running on the Fediverse network";
      license = licenses.agpl3Plus;
      homepage = "https://kbin.pub/";
      maintainers = with maintainers; [imsofi];
      platforms = php82.meta.platforms;
    };
  })
