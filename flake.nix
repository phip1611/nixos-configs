{
  description = "System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Needs flake inputs "nixpkgs" and "nixpkgs-unstable".
    phip1611-common = {
      type = "github";
      owner = "phip1611";
      repo = "dotfiles";
      dir = "NixOS";
    };

  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ /* moduleWithSystem, */... }: {
      flake.nixosConfigurations = {
        # My personal PC at home where I've also have my Windows installed
        # (on a dedicated disk).
        homepc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # Passes the inputs as argument to configuration.nix
          specialArgs = inputs;
          modules = [
            ./hosts/homepc/configuration.nix
          ];
        };
      };

      systems = [
        "x86_64-linux"
      ];

      perSystem = { config, pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixos-rebuild
            nixpkgs-fmt
          ];
        };
      };
    });
}
