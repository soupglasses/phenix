{
  lib,
  python3Packages,
  fetchFromGitHub,
  openldap,
  cyrus_sasl,
}:
python3Packages.buildPythonPackage rec {
  pname = "slapd";
  version = "0.1.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "python-ldap";
    repo = "python-slapd";
    rev = "${version}";
    sha256 = "sha256-OJudXLZy5E3FpuI0TZr41uBvrx7LzKGwT1tvug6Rrug=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "poetry>=1.0.0" "poetry-core" \
      --replace "poetry.masonry.api" "poetry.core.masonry.api"
  '';

  nativeBuildInputs = [
    python3Packages.poetry-core
    cyrus_sasl
  ];

  nativeCheckInputs = with python3Packages; [
    coverage
    mock
    openldap
    tox
    pytest-cov
    pytestCheckHook
  ];

  preCheck = ''
    # Needed by tests to setup a mockup ldap server.
    export BIN="${openldap}/bin"
    export SBIN="${openldap}/bin"
    export SLAPD="${openldap}/libexec/slapd"
    export SCHEMA="${openldap}/etc/schema"
  '';

  pythonImportsCheck = ["slapd"];

  meta = with lib; {
    description = "Controls a slapd process in a pythonic way";
    homepage = "https://github.com/python-ldap/python-slapd";
    license = licenses.mit;
    maintainers = with maintainers; [imsofi];
  };
}
