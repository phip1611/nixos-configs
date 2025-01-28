{
  pkgs ? import <nixpkgs> { },
}:

let
  tinykernel = import ./default.nix { inherit pkgs; };
in
pkgs.mkShell {
  inputsFrom = [ tinykernel ];
  packages = with pkgs; [
    gnumake
    qemu
  ];
}
