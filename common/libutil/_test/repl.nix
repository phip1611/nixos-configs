# Provides easy access to all attributes via
# - `nix repl --file repl.nix` and
# - `nix-build repl.nix -A <attr>`

let
  pkgs = import <nixpkgs> { };
  libutil = import ../. { inherit pkgs; };
in
(import ./tests.nix {
  inherit pkgs;
  inherit libutil;
})
