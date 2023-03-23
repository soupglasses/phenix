{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "smtpdfix";
  version = "0.4.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-B8/zudZrPbZJss2ybuWwBqTMTe94U6ZXbuFYJBxp7UI=";
  };

  propagatedBuildInputs = with python3Packages; [
    aiosmtpd
    cryptography
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
