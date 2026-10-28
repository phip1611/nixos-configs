# Tests the system and user-env modules in their base configuration, as on all
# my hosts, without the optional, heavy parts (GUI, dev toolchains, ...).

{ lib, ... }:

{
  name = "base-system";

  nodes.machine = {
    phip1611.common = {
      system.enable = true;
      user-env = {
        enable = true;
        username = "alice";
        git.username = "Alice";
        git.email = "alice@example.com";
      };
    };
    users.users.alice.isNormalUser = true;
    # Like all NixOS tests, save the time to build the NixOS manual.
    documentation.nixos.enable = lib.mkForce false;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    with subtest("the user environment is activated"):
        machine.wait_for_unit("home-manager-alice.service")
        machine.succeed(
            "getent passwd alice | grep -q ':/run/current-system/sw/bin/zsh$'",
            "cmp ${../../common/modules/user-env/DEFAULT_GLOBAL_AGENTS.md}"
            " /home/alice/.claude/CLAUDE.md",
        )

    with subtest("zsh and tmux start with my configuration without errors"):
        out = machine.succeed("su - alice -c 'zsh -i -c \"echo ok\"' 2>&1")
        # zplug fails to download its plugins without internet access.
        assert out.strip().splitlines()[-1] == "ok", out
        assert "command not found" not in out and "parse error" not in out, out
        machine.succeed("su - alice -c 'tmux new-session -d && tmux kill-server'")

    with subtest("git uses the configured identity"):
        out = machine.succeed("su - alice -c 'git config user.email'")
        assert out.strip() == "alice@example.com", out

    with subtest("my packages are available to the user"):
        machine.succeed("su - alice -c 'command -v link-to-copy zsh-history-backup'")

    with subtest("nix is configured"):
        out = machine.succeed("nix config show experimental-features")
        assert "flakes" in out, out
        machine.succeed("test -e /etc/nixos-current-system-flake-src/flake.nix")
  '';
}
