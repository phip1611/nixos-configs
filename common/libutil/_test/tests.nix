# List of tests for libutil.
#
# Each actual test (not helper attribute) should be prefixed with "test" and
# evaluates to a derivation that either succeeds or fails. Further, all test
# attributes must be non-flat derivations, i.e., produce an out directory and
# not a single file, so that they can be passed to symlinkJoin.

{ pkgs
, libutil
}:

let
  # Helper that transforms a bash condition to a succeeding or failing
  # derivation.
  bashCondToDrv = testName: bashCond: pkgs.runCommandLocal "bash-cond-to-drv-${testName}"
    {
      nativeBuildInputs = [ pkgs.ansi ];
    } ''
    # Bash strict mode.
    set -euo pipefail

    set +e
    if [[ ${bashCond} ]]; then
      mkdir $out
      exit 0
    fi
    set -e

    echo -e "$(ansi bold)$(ansi red)Condition '${bashCond}' for test '${testName}' not met!$(ansi reset)"
    exit 1
  '';

  builders = rec {
    base = pkgs.hello;
    flattened = libutil.builders.flattenDrv {
      drv = base;
      artifactPath = "bin/hello";
    };
    unflattened = libutil.builders.unflattenDrv {
      drv = flattened;
      artifactPath = "bin/hello";
    };
    testFlattened = bashCondToDrv "testFlattened" "-L ${flattened} || -f ${flattened}";
    testUnflattened = bashCondToDrv "testUnflattened" "-d ${unflattened}";
  };
in
{
  inherit builders;
}
