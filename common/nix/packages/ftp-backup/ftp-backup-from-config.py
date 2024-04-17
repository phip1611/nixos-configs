#!/usr/bin/env python3

# This tool is a convenient wrapper around my "ftp-backup" script that reads
# a config file

import datetime
import subprocess
import sys
import json
import os

DEFAULT_CONFIG_NAME = ".ftp-backup.config.json"


def generate_backup_path(host):
    # Get current timestamp in the format yyyy-mm-dd
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d")

    # Construct the path
    home = os.path.expanduser("~")
    downloads_path = os.path.join(home, "Downloads")
    backup_path = os.path.join(downloads_path, "FTP-Backups")
    final_path = os.path.join(backup_path, f"{timestamp}_{host}")

    return final_path


def read_config(file_path):
    try:
        with open(file_path, "r") as f:
            config_data = json.load(f)
            return config_data
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None
    except json.JSONDecodeError:
        print(f"Error decoding JSON in file: {file_path}")
        return None


def main():
    # Get file path from command line argument or use default.
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        # Default file path
        default_file_path = os.path.join(os.getenv("HOME"), DEFAULT_CONFIG_NAME)
        file_path = default_file_path

    # Read the config JSON.
    config_list = read_config(file_path)

    for config in config_list:
        # Secrets are passed as environment variable to not appear in the
        # processlist.
        env = os.environ.copy()
        env["FTP_PASS"] = config["pass"]
        subprocess.run(
            [
                "ftp-backup",
                "--host",
                config["host"],
                "--user",
                config["user"],
                "--keep",
                "--target",
                generate_backup_path(config["host"]),
            ],
            env=env,
        )


if __name__ == "__main__":
    main()
