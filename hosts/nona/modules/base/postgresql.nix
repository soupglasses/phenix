{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    port = 5432;
    package = pkgs.postgresql_14;
  };
}
