# This overlay adds my bootitems to nixpkgs under the "phip1611" key.

{ memtouchInput }:

final: prev:

{
  phip1611 = (prev.phip1611 or { }) // {
    bootitems = import ./default.nix {
      memtouch  = memtouchInput.packages.${final.stdenv.hostPlatform.system}.default;
      pkgs = final;
      libutil = final.phip1611.libutil;
    };
  };
}
