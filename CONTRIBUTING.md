# CONTRIBUTING.md

This repo follows a modified version of [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
applying the [nixpkgs's contributing guidelines](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
on-top of it.

The following document explains the differences diverging from the standard format.

## Git formatting:

* The commit message **MUST** all be lowercased. The body of the commit has no such restriction.
* **BREAKING CHANGE**: a commit that introduces a breaking API change (similar to *MAJOR* in Semantic Versioning) **MUST** include a footer in the style of `BREAKING CHANGE: <description>`.

```
<pkg-name>: (<version> -> <version> | init at <version> | <type? feat> <reason>)
<module-name>: <type? feat> <reason>
host/<host-name>: <type? feat> <reason>
<type>: <reason>
```

Types:

* **type**: follows conventional commits, `fix`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`, however its optional unless at the top level. Omitting type should be preferred, only add a type if it can explain the change on its own. If not, rephrase the reason to fit the pattern "feat: reason" or "docs: reason", depending on the commit style's default type.
* **version**: typically semantic version of a package. Follows nixpkgs conventions.

Names:

* *pkg-name*: typically the name of the folder holding a `default.nix` file somewhere under the `packages/` folder.
* *module-name*: typically the name of the `.nix` file in a `modules/` folder. Never apped the file type. This may also include per-host modules plus overlays and tests relating to supporting a module.
* *host-name*: typically the name of the folder under `hosts/` folder.


## Committing

We use pre-commit. You can check a commit without it using `nix flake check` but this is not recommended.
