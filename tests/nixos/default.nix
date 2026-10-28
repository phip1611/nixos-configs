# NixOS VM tests for my modules, services, and packages. Each test covers one
# area and runs as a flake check.
#
# The test nodes import the same modules as my hosts (see `buildNixosSystem`
# in flake.nix), so the tests exercise the modules as I use them.

{
  pkgs,
  # The flake inputs, including `self`.
  inputs,
}:

let
  runTest =
    test:
    pkgs.testers.runNixOSTest {
      imports = [ test ];
      # The modules are evaluated with flake inputs as module arguments, as
      # on my hosts.
      node.specialArgs = inputs;
      # My overlays module sets `nixpkgs.overlays`, which needs a nixpkgs
      # instance per node.
      node.pkgsReadOnly = false;
      defaults = {
        imports = builtins.attrValues inputs.self.nixosModules ++ [
          inputs.home-manager.nixosModules.home-manager
        ];
        # No internet access, also not in interactive runs outside the
        # Nix sandbox. Some services would download GiBs otherwise.
        virtualisation.restrictNetwork = true;
      };
    };
in
{
  base-system = runTest ./base-system.nix;
  network-boot = runTest ./network-boot.nix;
  packages = runTest ./packages.nix;
  services = runTest ./services.nix;
}
