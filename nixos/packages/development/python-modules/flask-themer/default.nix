{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage rec {
  pname = "flask-themer";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "TkTech";
    repo = "flask-themer";
    rev = "v${version}";
    sha256 = "sha256-2Zw+gKKN0kfjYuruuLQ+3dIFF0X07DTy0Ypc22Ih66w=";
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
