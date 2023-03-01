{system ? builtins.currentSystem}:
(import ./default.nix {inherit system;}).devShells.${system}.default
