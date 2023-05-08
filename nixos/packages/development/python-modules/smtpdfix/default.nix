{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "smtpdfix";
  version = "0.5.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-BCF1APYwxlsV/zFEV7py/Pn5t8auPnwM5IzbLQud5Gk=";
  };

  propagatedBuildInputs = with python3Packages; [
    aiosmtpd
    cryptography
    portpicker
    python-dotenv
  ];

  checkInputs = with python3Packages; [
    pytestCheckHook
    pytest-asyncio
  ];

  disabledTests = [
    # Contains odd 8025 == 5025 assertions that always fail
    "test_init_envfile"
    "test_config_file"
  ];

  pythonImportsCheck = ["smtpdfix"];

  meta = with lib; {
    description = "A SMTP server for use as a pytest fixture that implements encryption and authentication.";
    homepage = "https://github.com/bebleo/smtpdfix";
    license = licenses.mit;
    maintainers = with maintainers; [imsofi];
  };
}
