# Tests all services of the services module in one VM.

{ pkgs, ... }:

let
  ddnsConfig =
    password:
    pkgs.writeText "ddns-update.json" (
      builtins.toJSON {
        scheme = "http";
        host = "localhost";
        username = "ddns";
        inherit password;
        expect-message = "good";
      }
    );
in
{
  name = "services";

  nodes.machine =
    { pkgs, ... }:
    {
      phip1611.services = {
        ddns-update = {
          enable = true;
          configPath = "/etc/ddns-update.json";
        };
        flake-prefetch.enable = true;
        nix-verify-store.enable = true;
        rustup-gc-roots.enable = true;
        rustup-toolchains-update.enable = true;
        zsh-history-backup.enable = true;
      };

      # A DDNS server that accepts the update only with the right password.
      services.nginx = {
        enable = true;
        virtualHosts.localhost = {
          basicAuth.ddns = "secret";
          # Not `return`, which nginx handles before it checks the password.
          root = pkgs.writeTextDir "index.html" "good";
        };
      };

      # The metered check of the download services queries NetworkManager.
      networking.networkmanager.enable = true;

      users.users.alice = {
        isNormalUser = true;
        # Starts the user manager at boot, which runs the user services.
        linger = true;
      };

      # In the store but not rooted by the system.
      virtualisation.additionalPaths = [
        pkgs.hello
        pkgs.cowsay
      ];
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("user@1000.service")
    import shlex
    user_systemctl = "systemctl --user --machine=alice@ "

    def journal_cursor():
        return machine.succeed(
            "journalctl -n 1 --show-cursor -o cat | sed -n 's/^-- cursor: //p'"
        ).strip()

    def wait_for_user_unit_log(unit, cursor, text):
        """Waits until the log of a user unit of alice since cursor has text."""
        # The messages from systemd about the unit and those of its
        # processes.
        matches = f"_UID=1000 USER_UNIT={unit} + _UID=1000 _SYSTEMD_USER_UNIT={unit}"
        machine.wait_until_succeeds(
            f"journalctl --after-cursor={shlex.quote(cursor)} -o cat {matches}"
            f" | grep -F {shlex.quote(text)}",
            timeout=30,
        )

    with subtest("ddns-update sends the update and checks the response"):
        machine.wait_for_unit("nginx.service")
        machine.succeed("install -m 0600 ${ddnsConfig "secret"} /etc/ddns-update.json")
        machine.succeed("systemctl start ddns-update.service")
        machine.succeed("install -m 0600 ${ddnsConfig "wrong"} /etc/ddns-update.json")
        machine.fail("systemctl start ddns-update.service")

    with subtest("zsh-history-backup backs up and restores a truncated history"):
        backups = "/home/alice/.local/share/zsh-history-backup/backups"
        machine.succeed("su alice -c 'printf \"a\\nb\\nc\\n\" > ~/.zsh_history'")
        machine.succeed(user_systemctl + "start zsh-history-backup.service")
        machine.succeed(f"test $(wc -l < {backups}/.zsh_history.latest) -eq 3")
        machine.succeed(f"ls {backups}/*-zsh-history.zstd")

        machine.succeed("su alice -c 'echo a > ~/.zsh_history'")
        machine.succeed(user_systemctl + "start zsh-history-backup.service")
        machine.succeed("test $(wc -l < /home/alice/.zsh_history) -eq 3")

    with subtest("rustup-gc-roots roots the store paths that toolchains reference"):
        hello = "${pkgs.hello}"
        cowsay = "${pkgs.cowsay}"
        # A fake toolchain binary that references hello.
        machine.succeed(
            "su alice -c 'mkdir -p ~/.rustup/toolchains/stable/bin'",
            f"su alice -c \"printf '\\x7fELF {hello}/lib'"
            " > ~/.rustup/toolchains/stable/bin/rustc\"",
            "chmod +x /home/alice/.rustup/toolchains/stable/bin/rustc",
        )

        machine.succeed("systemctl start rustup-gc-roots.service")
        machine.succeed(f"test -L /nix/var/nix/gcroots/rustup-toolchains/$(basename {hello})")
        machine.succeed("nix-store --gc")
        machine.succeed(f"test -e {hello}")
        machine.fail(f"test -e {cowsay}")

    with subtest("nix-verify-store verifies the store"):
        machine.succeed("systemctl start nix-verify-store.service")

    with subtest("download services skip their run on a metered connection"):
        # The restricted user network of QEMU provides no default route, so
        # we add one to the NetworkManager connection.
        dev = "eth0"
        conn = machine.succeed(f"nmcli -g GENERAL.CONNECTION device show {dev}").strip()
        machine.succeed(f"nmcli connection modify '{conn}' ipv4.routes '0.0.0.0/0 10.0.2.2'")

        def set_metered(value):
            machine.succeed(f"nmcli connection modify '{conn}' connection.metered {value}")
            machine.succeed(f"nmcli connection up '{conn}'")
            machine.wait_until_succeeds(
                f"nmcli -g GENERAL.METERED device show {dev} | grep -x {value}"
            )
            machine.wait_until_succeeds(f"ip route show default | grep 'dev {dev}'")

        set_metered("yes")
        for unit in ["flake-prefetch.service", "rustup-toolchains-update.service"]:
            cursor = journal_cursor()
            machine.succeed(user_systemctl + f"start {unit}")
            wait_for_user_unit_log(unit, cursor, "is metered")
            wait_for_user_unit_log(unit, cursor, "Skipped due to 'exec-condition'")

        # Without a metered connection, the run starts. It fails, as there
        # is no internet access.
        set_metered("no")
        unit = "rustup-toolchains-update.service"
        cursor = journal_cursor()
        machine.fail(user_systemctl + f"start {unit}")
        wait_for_user_unit_log(unit, cursor, "is not metered")
  '';
}
