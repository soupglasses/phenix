<p align="center">
  <a href="https://www.youtube.com/watch?v=pDSptPcImGE/#gh-light-mode-only">
    <img src="/media/phenix-light.png" height="100"/>
  </a>
  <a href="https://www.youtube.com/watch?v=pDSptPcImGE/#gh-dark-mode-only">
    <img src="/media/phenix-dark.png" height="100"/>
  </a>
</p>

# Phenix

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This repository contains the infrastructure as code for Phenix, my personal infrastructue.

## Deployment

```bash
$ nix develop
 ...
$ deploy .#hostname
```

## Software used

Deployment to hosts: [deploy-rs](https://github.com/serokell/deploy-rs)

Secrets: [sops-nix](https://github.com/Mic92/sops-nix)

Packaging and dependency management: [nix-flakes](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html)

## Hosts

### [Nona](https://en.wikipedia.org/wiki/Nona_(mythology))
- Name: Roman goddess of pregrancy, the life giver.
- Use: General server, holds most core services.

### [Lumity](https://en.wikipedia.org/wiki/The_Owl_House#LGBTQ+_representation)
- Name: Two characters from The Owl House.
- Use: Large storage server, storing larger files.
