{ pkgs }:

let
  src = ./.;
  dirEntries = builtins.readDir ./.;
  # All directory names.
  packageDirs = builtins.filter (n: dirEntries.${n} == "directory") (builtins.attrNames dirEntries);
  callPackages =
    names:
    builtins.foldl' (
      acc: package:
      acc
      // {
        "${package}" = pkgs.callPackage "${src}/${package}" { };
      }
    ) { } names;
in
callPackages packageDirs
