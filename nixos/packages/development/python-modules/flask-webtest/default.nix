{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage rec {
  pname = "flask-webtest";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "aromanovich";
    repo = "flask-webtest";
    rev = "${version}";
    sha256 = "sha256-Yih+7cGgK9s41Z5b2FDtqgs5FZhfnXFzw20/vOeRp2o=";
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
