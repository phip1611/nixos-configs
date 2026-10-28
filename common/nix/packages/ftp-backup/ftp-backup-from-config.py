#!/usr/bin/env python3

"""
This tool is a convenient wrapper around my "ftp-backup" script that reads
a config file and backups all FTP hosts specified there.
"""

import datetime
import subprocess
import sys
import json
import os

from pathlib import Path
from typing import TypedDict, List


class FTPHostConfig(TypedDict):
    """
    Configuration of an FTP host to back up including a list of directories.
    The default configuration should be set to "/".
    """

    host: str
    user: str
    # use `pass_` because `pass` is a reserved keyword
    pass_: str
    dirs: List[Path]
    description: str


def generate_backup_paths(host: str, description: str) -> tuple[Path, Path]:
    """
    Generates the paths where the backup should be stored.
    :param host: Hostname (file path friendly)
    :param description: Description of the backup, e.g. "wordpress-xyz" (file path friendly)
    :return: Path to the mirror directory and path to the archive
    """
    # Get current timestamp in the format yyyy-mm-dd
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d")

    backup_path = Path.home() / "Downloads" / "FTP-Backups"
    if not backup_path.exists():
        print(f"Creating directory: {backup_path}")
        backup_path.mkdir(parents=True)

    # The mirror is reused by every backup, so that only new and changed
    # files are downloaded. Each backup gets its own archive.
    mirror_path = backup_path / f"{host}_{description}"
    archive_path = backup_path / f"{timestamp}_{host}_{description}.tar.zst"

    return mirror_path, archive_path


def get_user_config_file() -> Path:
    """
    Returns the path of the user's configuration file and ensures that it exists.
    :return: Path to the config file
    """
    path = Path.home() / ".config" / "ftp-backup" / "config.json"

    # Check explicitly that the file exists and is a file
    if not path.is_file():
        raise FileNotFoundError(f"Configuration file not found: {path}")

    return path


class ConfigError(Exception):
    """Raised when the configuration file is missing or invalid."""

    pass


def read_config(file_path: Path) -> List[FTPHostConfig]:
    """
    Reads the configuration file and returns a list with FTP hosts to back up.
    :param file_path:
    :return:
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            config_data = json.load(f)

    except FileNotFoundError as e:
        raise ConfigError(f"Configuration file not found: {file_path}") from e
    except json.JSONDecodeError as e:
        raise ConfigError(f"Invalid JSON in configuration file: {file_path}") from e

    # Normalize reserved keyword
    for entry in config_data:
        if "pass" in entry:
            entry["pass_"] = entry.pop("pass")

    return config_data


def main():
    # Backups often contain secrets, such as database credentials of a
    # website.
    os.umask(0o077)

    # Get file path from command line argument or use default.
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        file_path = get_user_config_file()

    # Read the config JSON.
    hosts = read_config(file_path)

    # Iterate all FTP hosts and create a backup for each. A failed backup
    # doesn't stop the backups of the other hosts.
    failed_hosts = []
    for host in hosts:
        # Secrets are passed as environment variable to not appear in the
        # processlist.
        env = os.environ.copy()
        mirror_path, archive_path = generate_backup_paths(
            host["host"], host["description"]
        )
        env["FTP_PASS"] = host["pass_"]
        result = subprocess.run(
            [
                "ftp-backup",
                "--host",
                host["host"],
                "--user",
                host["user"],
                "--keep",
                "--target",
                mirror_path,
                "--archive",
                archive_path,
                *host["dirs"],
            ],
            env=env,
        )
        if result.returncode != 0:
            failed_hosts.append(f"{host['host']} ({host['description']})")

    if failed_hosts:
        print(f"Backups failed: {', '.join(failed_hosts)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
