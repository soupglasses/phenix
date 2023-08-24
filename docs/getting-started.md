# Getting Started

## 1. Install Nix

Find a way to install Nix on your preferred platform of choice.
Here is a short list of current methods of install:

### 1: Use your package manager

Use dnf or apt to manage the nix install.

<https://github.com/nix-community/nix-installers/>

### 2: Use the installer script from NixOS's website

This is the official method to install nix. It however can be slightly buggy,
especially under SELinux enabled distributions, such as Fedora.

Keep in mind you will need to add the following to either
`~/.config/nix/nix.conf` or `/etc/nix/nix.conf` to get flakes to work correctly:

```bash
experimental-features = nix-command flakes
```

<https://nix.dev/tutorials/install-nix>

### 3: Experimental installer script from Determinate Systems

An external company's attempt to create a better install script than the
official methods. May work better if the previous two approaches are insufficient.

<https://github.com/DeterminateSystems/nix-installer>

## Install Direnv

You need to find a way to install direnv with at least version `2.23.0` to
work correctly inside this repository.

### Install direnv with package manager.

Use your preferred package manager (apt/dnf/pacman/...) to install direnv.

For a list of packages, see here: <https://repology.org/project/direnv>

### Install direnv with nix

A tip is that you can also install this through Nix if your preferred method of
installation does not include a recent enough version of direnv.

While the recommended methods of using nix is through `nix shell` and
`nix run`, or through programs such as `nixos-rebuild` and `home-manager`,
a simple (but frowned upon) method is to use `nix profile install`.
This will mimmic the likes of traditional package managers like `apt` or `dnf`.

Please read more about how this works in the below link, and further see
the page: [Introduction to Nix](./introduction-to-nix.md).

<https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile.html>
