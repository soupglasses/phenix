{
  lib,
  python3,
  fetchFromGitLab,
  # Test dependencies
  openldap,
  # Custom python dependencies
  flask-themer,
  flask-webtest,
  slapd,
  smtpdfix,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "canaille";
  version = "0.0.22";
  format = "pyproject";

  src = fetchFromGitLab {
    owner = "yaal";
    repo = "canaille";
    rev = "${version}";
    sha256 = "sha256-nsrqqp49Vv8vmJ4/ug4SF5+nhOeTiCiq6h5VES9Ft00=";
  };

  patches = [
    ./0001-wip-allow-_file-extention-on-config-keys.patch
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "poetry.masonry.api" "poetry.core.masonry.api"
  '';

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
  ];

  nativeCheckInputs = with python3.pkgs; [
    coverage
    faker
    flask-webtest
    freezegun
    mock
    openldap
    pytest
    pytest-cov
    pytest-httpserver
    pytestCheckHook
    pyquery
    slapd
    smtpdfix
  ];

  propagatedBuildInputs = with python3.pkgs; [
    authlib
    click
    email_validator
    flask
    flask-babel
    flask-themer
    flask_wtf
    ldap
    pycountry
    sentry-sdk
    toml
    wtforms
  ];

  preCheck = ''
    # Needed by tests to setup a mockup ldap server.
    export BIN="${openldap}/bin"
    export SBIN="${openldap}/bin"
    export SLAPD="${openldap}/libexec/slapd"
    export SCHEMA="${openldap}/etc/schema"
  '';

  postInstall = ''
    mkdir -p $out/etc/schema
    cp $out/lib/${python3.libPrefix}/site-packages/canaille/ldap_backend/schemas/* $out/etc/schema/
  '';

  meta = with lib; {
    description = "Simplistic OpenID Connect provider over OpenLDAP";
    homepage = "https://gitlab.com/yaal/canaille";
    license = licenses.mit;
    maintainers = with maintainers; [imsofi];
  };
}
