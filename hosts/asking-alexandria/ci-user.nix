# Creates a non-privileged user that CI instances can use, such as the GitHub
# CI, to fill the Nix cache of this host.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = "ci-builder";
in
{
  users.users.ci-builder = {
    isNormalUser = true;
    createHome = true;
    description = username;
    openssh.authorizedKeys.keys = [
      # `restrict`: no forwarding, no PTY, no ~/.ssh/rc.
      "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmacK8ivbooOAUjJgK3Nu4C8pjo8BS13cPcyDvjoQx6 ci-builder@nix-binary-cache.phip1611.dev"
    ];
  };

  services.openssh.settings.AllowUsers = [ username ];

  # The CI only runs commands and copies files.
  # - Public keys only: `PasswordAuthentication no` alone still allows
  #   password logins via PAM (keyboard-interactive).
  # - No forwarding: otherwise, the CI key could reach services that only
  #   listen on localhost, such as netdata without its basic auth.
  services.openssh.extraConfig = ''
    Match User ${username}
      AuthenticationMethods publickey
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding no
      PermitTTY no
      PermitTunnel no
      X11Forwarding no
  '';
}
