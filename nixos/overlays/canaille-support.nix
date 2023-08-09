final: prev: {
  python3 = prev.python3.override {
    packageOverrides = _python-final: python-prev: {
      authlib = python-prev.authlib.overrideAttrs rec {
        version = "1.2.1";
        src = final.fetchFromGitHub {
          owner = "lepture";
          repo = "authlib";
          rev = "refs/tags/v${version}";
          hash = "sha256-K6u590poZ9C3Uzi3a8k8aXMeSeRgn91e+p2PWYno3Y8=";
        };
      };
    };
  };
}
