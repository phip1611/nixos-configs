{ pkgs }:

let
  template = builtins.readFile ./nix-shell-init.template;
in
pkgs.writeShellScriptBin "nix-shell-init" ''
  echo -n "${template}" > $PWD/shell.nix
''
