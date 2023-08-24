# Patching

## Patching NixOS Packages by overlay

Todo.

## Patching NixOS Modules by Import

I will use the nixos module `minecraft-server.nix` for my example.

First step is to create the actual module with your modification.

```nix
# ./modules/example-module.nix
{config, lib, pkgs, ... }:
{
  ...
}
```

If you are modifying a module inside of `nixpkgs/nixos`, you will need to disable that module inside of your modification. You can use https://search.nixos.org/options to find the location of your service file.

Here is an example for how to disable `services.minecraft-server`. I would recommend to put this as close to the top of your module to make it easier to see.

```nix
{config, lib, pkgs, ... }:
{
  imports = [ ./modules/minecraft-server.nix ];
  disabledModules = [ "services/games/minecraft-server.nix" ];
}
```
