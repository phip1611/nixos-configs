# I use the following priority to configure programs:
# 1.) `programs.*.enable` options from NixOS
# 2.) `programs.*.enable` options from home-manager
# 3.) directly adding pkgs to the PATH
#
# While I agree that you should not have all packages globally installed and
# instead move them to a Nix shell of a project, I like having all the cool
# tools listed here, as:
# - this makes man pages accessible right away
# - I can keep track of all awesome tooling that exists and that I like

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./cli
    ./gui
    ./dev.nix
    ./media.nix
  ];
}
