# Provides easy access to all attributes via
# - `nix repl --file repl.nix` and
# - `nix-build repl.nix -A <attr>`

import ./default.nix {
  pkgs = import <nixpkgs> { };
}
