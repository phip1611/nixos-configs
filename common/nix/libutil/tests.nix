# List of tests for libutil.
#
# Each actual test (not helper attribute) should be prefixed with "test" and
# evaluates to a derivation that either succeeds or fails. Further, all test
# attributes must be non-flat derivations, i.e., produce an out directory and
# not a single file, so that they can be passed to symlinkJoin.

{ pkgs }:

let
  inherit (pkgs.phip1611) libutil;

  builders =
    let
      base = pkgs.hello;
      flattened = libutil.builders.flattenDrv {
        drv = base;
        artifactPath = "bin/hello";
      };
      unflattened = libutil.builders.unflattenDrv {
        drv = flattened;
        artifactPath = "bin/hello";
      };
    in
    {
      testFlattened = libutil.testing.bashCondToDrv "testFlattened" "-L ${flattened} || -f ${flattened}";
      testUnflattened = libutil.testing.bashCondToDrv "testUnflattened" "-d ${unflattened}";
    };
in
{
  inherit builders;
}
