# This overlay adds my common pkgs to nixpkgs under the "phip1611" key.

final: prev:

{
  phip1611 = (prev.phip1611 or { }) // {
    pkgs = import ./default.nix {
      pkgs = final;
      # libutil = final.phip1611.libutil;
    };
  };
}
