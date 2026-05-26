# nixpkgs fallback is only here for quick prototyping. See README.md.
{
  pkgs ? builtins.trace "WARN: Using nixpkgs from ./nixpkgs.nix" (import ./nixpkgs.nix),
}:

let
  tests = {
    kernelbootTests = import ./kernelboot-tests.nix { inherit pkgs; };
    libutilTests = import ./libutil/tests.nix { inherit pkgs; };
  };
  libutil = import ./libutil { inherit pkgs; };
  bootitems = import ./bootitems { inherit libutil pkgs; };
  packages = import ./packages { inherit pkgs; };
in
{
  inherit bootitems libutil packages;
  # Combined derivation that exports the individual tests as passthru
  # attributes.
  allTests =
    (pkgs.symlinkJoin {
      name = "all-tests";
      paths =
        builtins.attrValues tests.kernelbootTests ++ builtins.attrValues tests.libutilTests.builders;
    }).overrideAttrs
      {
        passthru = {
          inherit (tests) kernelbootTests libutilTests;
        };
      };

  # Useful for quick prototyping.
  /*
    iso = libutil.images.x86.createMultibootIso {
      kernel = (libutil.builders.flattenDrv {
        drv = bootitems.tinytoykernel;
        artifactPath = "kernel.elf64";
      }).overrideAttrs { name = "tinytoykernel"; };
    };
  */
}
