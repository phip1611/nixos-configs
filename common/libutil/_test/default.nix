{ pkgs
, libutil ? import ../. { inherit pkgs; }
}:

let
  tests = import ./tests.nix {
    inherit pkgs;
    inherit libutil;
  };
in
pkgs.symlinkJoin {
  name = "libutil-tests";

  # Actual tests:
  paths = [
    # Check builders
    tests.builders.testFlattened
    tests.builders.testUnflattened
  ];
}
