# This overlay adds my libutil to nixpkgs under the "phip1611" key.

final: prev:

{
  phip1611 = (prev.phip1611 or { }) // {
    bootitems = import ./default.nix {
      pkgs = final;
    };
  };
}
