# Creates a non-privileged user that CI instances can use, such as the GitHub
# CI, to fill the Nix cache of this host.

{ config, lib, pkgs, ... }:

let
  username = "ci-builder";
in
{
  users.users.ci-builder = {
    isNormalUser = true;
    createHome = true;
    description = username;
    # TODO prevent password login via SSH for this single user?
    # initialPassword = username;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmacK8ivbooOAUjJgK3Nu4C8pjo8BS13cPcyDvjoQx6 ci-builder@nix-binary-cache.phip1611.dev"
    ];
  };

  # Prevent the password login for this user, always.
  services.openssh.extraConfig = ''
    Match User ${username}
      PasswordAuthentication no
  '';
}
