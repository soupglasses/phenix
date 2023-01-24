{...}: {
  services.nginx = {
    virtualHosts."byte.surf" = {
      useACMEHost = "byte.surf";
      forceSSL = true;
    };
  };

  security.acme.certs."byte.surf".group = "nginx";
}
