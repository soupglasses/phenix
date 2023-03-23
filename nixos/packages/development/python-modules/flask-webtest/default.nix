{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage rec {
  pname = "flask-webtest";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "aromanovich";
    repo = "flask-webtest";
    rev = "${version}";
    sha256 = "sha256-jOrH6pfQNcgg6JpGm+Rrvfw8eX/T0IP3H1z0+GU/XKs=";
  };

  propagatedBuildInputs = with python3Packages; [
    flask
    webtest
    blinker
  ];

  # tests expect availability to a sql server?
  doCheck = false;

  pythonImportsCheck = ["flask_webtest"];

  meta = with lib; {
    description = "Utilities for testing Flask applications with WebTest";
    homepage = "https://github.com/aromanovich/flask-webtest";
    license = licenses.bsd3;
    maintainers = with maintainers; [imsofi];
  };
}
