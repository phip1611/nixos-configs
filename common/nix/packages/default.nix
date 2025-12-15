{ pkgs }:

let
  src = ./.;
  dirEntries = builtins.readDir ./.;
  # All directory names.
  packageDirs = builtins.filter (n: dirEntries.${n} == "directory") (builtins.attrNames dirEntries);
  callPackages =
    names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = pkgs.callPackage (src + "/${name}") { };
      }) names
    );
in
callPackages packageDirs
