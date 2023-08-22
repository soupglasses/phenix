{
  imports = [
    ../../common
  ];

  # Very much TODO.

  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 31d";
}
