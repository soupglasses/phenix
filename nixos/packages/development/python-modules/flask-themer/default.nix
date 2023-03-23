{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage rec {
  pname = "flask-themer";
  version = "1.4.3";

  src = fetchFromGitHub {
    owner = "TkTech";
    repo = "flask-themer";
    rev = "v${version}";
    sha256 = "sha256-K2y0Ivy5eb8BV8Lb49Fng2X3gkF1jXbQus5lzhfd4bk=";
  };

  propagatedBuildInputs = with python3Packages; [
    flask
  ];

  checkInputs = with python3Packages; [
    pytest-cov
    pytestCheckHook
  ];

  pythonImportsCheck = ["flask_themer"];

  meta = with lib; {
    description = "Simple theming support for Flask apps.";
    homepage = "https://github.com/TkTech/flask-themer";
    license = licenses.mit;
    maintainers = with maintainers; [imsofi];
  };
}
