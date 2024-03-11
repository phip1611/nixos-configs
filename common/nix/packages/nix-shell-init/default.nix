{ pkgs }:

let
  template = builtins.readFile ./nix-shell-init.template.txt;
in
pkgs.writeShellScriptBin "nix-shell-init" ''
  echo -n "${template}" > $PWD/shell.nix
''
