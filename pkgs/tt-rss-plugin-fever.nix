{ lib, stdenv, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname = "tt-rss-plugin-fever";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "DigitalDJ";
    repo = "tinytinyrss-fever-plugin";
    rev = version;
    sha256 = "1y2z3gxbaml2ggzkpq4n4m9lp60zrwcs383cn4w3sc2pp8byg8bw";
  };

  installPhase = ''
        install -D init.php $out/fever/init.php
        install -D index.php $out/fever/index.php
    		install -D fever_api.php $out/fever/fever_api.php
  '';

  meta = with lib; {
    description = "An open source plugin which simulates the Fever API";
    licence = licences.gpl3;
    homepage = "https://github.com/DigitalDJ/tinytinyrss-fever-plugin";
    maintainers = with maintainers; [ imsofi ];
    platforms = platforms.all;
  };
}
