{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell rec {
  nativeBuildInputs = with pkgs; [
    binutils
    gcc
    grub2
    gnumake
  ];
}
