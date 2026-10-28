# Tests my packages from `common/nix/packages`. The services test covers the
# packages that back a service (ddns-update, flake-prefetch,
# is-network-unmetered, rustup-toolchains-update, and zsh-history-backup).

{ pkgs, ... }:

let
  # A self-signed CA and a certificate for the host "ftp".
  certs = pkgs.runCommand "ftp-certs" { nativeBuildInputs = [ pkgs.openssl ]; } ''
    mkdir $out
    openssl req -x509 -newkey rsa:2048 -nodes -days 36500 -subj /CN=test-ca \
      -keyout ca.key -out $out/ca.crt
    openssl req -newkey rsa:2048 -nodes -subj /CN=ftp \
      -keyout $out/ftp.key -out ftp.csr
    openssl x509 -req -in ftp.csr -CA $out/ca.crt -CAkey ca.key \
      -CAcreateserial -days 36500 -out $out/ftp.crt \
      -extfile <(printf 'subjectAltName=DNS:ftp')
  '';

  photo = pkgs.runCommand "photo.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 8x8 xc:red jpg:$out
  '';

  # Read from a file in the test, so that it doesn't appear in the arguments
  # of the commands of the test driver.
  ftpPassword = "S3cretPw";
  ftpPasswordFile = pkgs.writeText "ftp-password" ftpPassword;

  ftpBackupConfig = pkgs.writeText "ftp-backup-config.json" (
    builtins.toJSON [
      {
        host = "ftp";
        user = "bob";
        pass = "wrong";
        dirs = [ "data" ];
        description = "bad";
      }
      {
        host = "ftp";
        user = "bob";
        pass = ftpPassword;
        dirs = [ "data" ];
        description = "good";
      }
    ]
  );

  # An empty disk for a virtual USB stick.
  usbStick = pkgs.runCommand "usb-stick.img" { } ''
    truncate -s 64M $out
  '';
in
{
  name = "packages";

  nodes.machine =
    { pkgs, ... }:
    {
      environment.systemPackages =
        builtins.attrValues pkgs.phip1611.packages
        ++ (with pkgs; [
          exiftool
          git
          tmux
          zstd
        ]);

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Don't fetch the global flake registry from the internet.
        flake-registry = "";
      };

      security.pki.certificateFiles = [ "${certs}/ca.crt" ];

      users.users.alice.isNormalUser = true;

      # Logs the arguments of all executed programs, to check that no
      # password appears there.
      security.audit = {
        enable = true;
        backlogLimit = 8192;
        rules = [ "-a exit,always -F arch=b64 -S execve" ];
      };
      security.auditd.enable = true;

      # A removable USB stick. Writes go to a temporary overlay.
      virtualisation.qemu.options = [
        "-device qemu-xhci"
        "-drive if=none,id=usbstick,format=raw,snapshot=on,file=${usbStick}"
        "-device usb-storage,drive=usbstick,removable=on"
      ];
    };

  # An FTPS server for ftp-backup.
  nodes.ftp = {
    # Local users log in via PAM.
    security.pam.services.vsftpd.enable = true;
    services.vsftpd = {
      enable = true;
      localUsers = true;
      forceLocalLoginsSSL = true;
      forceLocalDataSSL = true;
      rsaCertFile = "${certs}/ftp.crt";
      rsaKeyFile = "${certs}/ftp.key";
      # lftp doesn't reuse the TLS session of the control connection for
      # data connections.
      # Users see their home as "/", as at a typical web hoster.
      extraConfig = ''
        require_ssl_reuse=NO
        chroot_local_user=YES
        allow_writeable_chroot=YES
      '';
    };
    networking.firewall.enable = false;
    users.users.bob = {
      isNormalUser = true;
      password = ftpPassword;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    with subtest("colortest prints the color table"):
        machine.succeed("colortest > /tmp/colortest && grep -q gYw /tmp/colortest")

    with subtest("link-to-copy replaces a symlink with a copy"):
        machine.succeed(
            "mkdir /tmp/ltc && echo hello > /tmp/ltc/file && ln -s file /tmp/ltc/link",
            "link-to-copy /tmp/ltc/link --mode 0600",
            "test ! -L /tmp/ltc/link",
            "test \"$(cat /tmp/ltc/link)\" = hello",
            "test $(stat -c %a /tmp/ltc/link) = 600",
        )
        machine.fail("link-to-copy /tmp/ltc/file")

    with subtest("repeat-cmd repeats a command until it fails or succeeds"):
        # Succeeds in the first two iterations and fails afterwards.
        step = "n=$(( $(cat /tmp/n 2>/dev/null || echo 0) + 1 )); echo $n > /tmp/n; [ $n -lt 3 ]"
        machine.fail(f"repeat-cmd -- sh -c '{step}'")
        machine.succeed("test $(cat /tmp/n) -eq 3 && rm /tmp/n")
        machine.succeed(f"repeat-cmd --invert -- sh -c '! ({step})'")
        machine.succeed("test $(cat /tmp/n) -eq 3")

    with subtest("list-old-system-profiles lists all but the newest profiles"):
        machine.succeed(
            "mkdir /tmp/profiles",
            "for i in $(seq 1 11); do ln -s /nonexistent /tmp/profiles/system-$i-link; done",
        )
        out = machine.succeed("list-old-system-profiles --skip 3 --dir /tmp/profiles")
        assert out.split() == [f"/tmp/profiles/system-{i}-link" for i in range(1, 9)], out

    with subtest("normalize-file-permissions normalizes owners and modes"):
        machine.succeed(
            "mkdir -p /tmp/perm/sub && touch '/tmp/perm/sub/a file'",
            "chmod 0700 /tmp/perm/sub && chmod 0600 '/tmp/perm/sub/a file'",
            # Not from within the directory, so the script must not touch the
            # current directory.
            "mkdir /tmp/cwd && touch /tmp/cwd/other && chmod 0600 /tmp/cwd/other",
            "cd /tmp/cwd && normalize-file-permissions --user alice --group users"
            " --directory /tmp/perm",
            "test $(stat -c %a /tmp/cwd/other) = 600",
        )
        for path, mode in [("/tmp/perm/sub", "755"), ("/tmp/perm/sub/a file", "644")]:
            out = machine.succeed(f"stat -c '%U %G %a' '{path}'").strip()
            assert out == f"alice users {mode}", (path, out)

    with subtest("keep-directory-diff keeps only new and changed files"):
        machine.succeed(
            "mkdir /tmp/kdd1 && echo a > /tmp/kdd1/changed && echo b > /tmp/kdd1/unchanged",
            "cp -r /tmp/kdd1 /tmp/kdd2 && echo c > /tmp/kdd2/changed && echo d > /tmp/kdd2/new",
            "keep-directory-diff /tmp/kdd1 /tmp/kdd2",
        )
        files = machine.succeed("cd /tmp/kdd2 && find . -type f | sort").split()
        assert files == ["./changed", "./new"], files

    with subtest("nix-shell-init creates a valid shell.nix"):
        machine.succeed(
            "mkdir /tmp/nsi && cd /tmp/nsi && nix-shell-init",
            "nix-instantiate --parse /tmp/nsi/shell.nix",
        )

    with subtest("clion-exclude-direnv excludes .direnv in the CLion project"):
        iml = "/tmp/clion/.idea/clion.iml"
        machine.succeed(
            "mkdir -p /tmp/clion/.idea",
            f"echo '<content url=\"file://$MODULE_DIR$\" />' > {iml}",
            "cd /tmp/clion && clion-exclude-direnv",
            f"grep -F 'excludeFolder url=\"file://$MODULE_DIR$/.direnv\"' {iml}",
        )

    with subtest("rename-photos-by-date renames photos in chronological order"):
        machine.succeed("mkdir /tmp/photos && echo notes > /tmp/photos/notes.txt")
        for name, year in [("b.jpg", 2021), ("a.jpg", 2020), ("c.JPG", 2019)]:
            machine.succeed(
                f"install -m 0644 ${photo} /tmp/photos/{name}",
                f"exiftool -q -overwrite_original"
                f" -DateTimeOriginal='{year}:01:01 10:00:00' /tmp/photos/{name}",
            )
        machine.succeed("rename-photos-by-date Trip --directory /tmp/photos --yes")
        for number, year in [(1, 2019), (2, 2020), (3, 2021)]:
            photo = f"/tmp/photos/Trip (00{number}).jpg"
            out = machine.succeed(f"exiftool -s3 -DateTimeOriginal '{photo}'")
            assert out.startswith(str(year)), (number, out)
        machine.succeed("test -f /tmp/photos/notes.txt")

    with subtest("wait-host-online waits for a host"):
        machine.succeed("wait-host-online 127.0.0.1 --timeout 5")
        machine.fail("wait-host-online 192.0.2.1 --timeout 2 --request-delay 0.2")

    with subtest("qemu-uefi and run-efi start"):
        machine.succeed("qemu-uefi -version")
        machine.succeed("run-efi --help")

    with subtest("flake-update-and-commit bumps the inputs and commits"):
        machine.succeed(
            "git config --global user.name test",
            "git config --global user.email test@example.com",
            "git config --global init.defaultBranch main",
            # A flake input with a commit from 2020.
            "mkdir /tmp/dep && cd /tmp/dep && git init -q"
            " && echo '{ outputs = _: { }; }' > flake.nix && git add flake.nix"
            " && GIT_COMMITTER_DATE=2020-01-01T00:00:00Z git commit -qm init",
            "mkdir /tmp/main && cd /tmp/main && git init -q"
            " && echo '{ inputs.dep.url = \"git+file:///tmp/dep\"; outputs = _: { }; }' > flake.nix"
            " && git add flake.nix && nix flake lock && git add flake.lock && git commit -qm init",
            # A new commit in the input from 2021.
            "cd /tmp/dep && echo '# change' >> flake.nix"
            " && GIT_COMMITTER_DATE=2021-01-01T00:00:00Z git commit -qam change",
        )
        machine.succeed("cd /tmp/main && flake-update-and-commit")
        message = machine.succeed("git -C /tmp/main log -1 --format=%B")
        assert message.startswith("flake: bump all dependencies"), message
        assert "dep: 2020-01-01" in message and "-> 2021-01-01" in message, message

    with subtest("format-usb-drive-bootable formats a removable drive"):
        # The script is interactive, so we drive it in tmux.
        def wait_for_screen(text):
            machine.wait_until_succeeds(
                f"tmux capture-pane -p -t usb | grep -F '{text}'", timeout=60
            )

        machine.succeed(
            "tmux new-session -d -s usb -x 200 -y 50"
            " 'format-usb-drive-bootable --name TESTUSB; echo EXIT=$?; sleep infinity'"
        )
        wait_for_screen("Select a removable USB drive")
        # The VM also has a floppy drive, which counts as removable disk.
        machine.succeed("tmux send-keys -t usb 64M Enter")
        wait_for_screen("Do you really want to reformat")
        machine.succeed("tmux send-keys -t usb y Enter")
        wait_for_screen("EXIT=")
        screen = machine.succeed("tmux capture-pane -p -S - -t usb")
        assert "EXIT=0" in screen, screen
        mountpoint = machine.succeed("findmnt -n -o TARGET -S LABEL=TESTUSB").strip()
        machine.succeed(
            f"test -d {mountpoint}/EFI/BOOT",
            "test $(lsblk -n -o FSTYPE /dev/disk/by-label/TESTUSB) = vfat",
        )

    with subtest("ftp-backup mirrors directories via FTPS and compresses them"):
        ftp.wait_for_unit("vsftpd.service")
        ftp.succeed(
            "su bob -c 'mkdir -p ~/data/sub && echo hello > ~/data/sub/file.txt'",
            "su bob -c 'mkdir ~/\"my data\" && echo hi > ~/\"my data\"/file.txt'",
        )
        machine.succeed(
            "cd /tmp && FTP_PASS=$(cat ${ftpPasswordFile}) ftp-backup --host ftp --user bob"
            " data 'my data' --target /tmp/ftp-backup --keep"
        )
        machine.succeed(
            "test \"$(cat /tmp/ftp-backup/data/sub/file.txt)\" = hello",
            "test \"$(cat '/tmp/ftp-backup/my data/file.txt')\" = hi",
            "tar -tf /tmp/ftp-backup.tar.zst | grep data/sub/file.txt",
        )

    with subtest("ftp-backup keeps the password out of the process list"):
        # Audit logs arguments in plain text or, with special characters, as
        # hex. The brackets keep the patterns from matching grep's own
        # arguments, in both forms.
        machine.fail("grep -E 'S3cretP[w]|53336372657450[7]7' /var/log/audit/audit.log")
        # Proves that the audit log has the arguments of lftp.
        machine.succeed("grep -F 'a0=\"lftp\"' /var/log/audit/audit.log")

    with subtest("ftp-backup-from-config backs up all hosts and reports failures"):
        # Not in the configured directories.
        ftp.succeed("su bob -c 'mkdir ~/other && echo x > ~/other/file.txt'")
        # The config contains passwords, so it must be private.
        machine.succeed("install -m 0600 ${ftpBackupConfig} /tmp/ftp-backup.json")
        # There is no ~/Downloads yet. The first host has a wrong password.
        machine.fail("ftp-backup-from-config /tmp/ftp-backup.json")
        backups = "/root/Downloads/FTP-Backups"
        machine.succeed(
            f"test \"$(cat {backups}/ftp_good/data/sub/file.txt)\" = hello",
            f"test ! -e {backups}/ftp_good/other",
            f"zstd -t {backups}/*_ftp_good.tar.zst",
        )
  '';
}
