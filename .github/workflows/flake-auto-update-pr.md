# Flake Auto Update via GitHub Actions

As long as Dependabot doesn't support Nix flakes [0], this CI action checks for
flake updates regularly (as specified in the workflow file).

The action creates a pull request through a dedicated GitHub App. This makes
the app, rather than a personal account, the pull request author. Its
installation token also allows the normal CI pipeline to run for the pull
request [1].

## Setup

1. Allow workflows to create pull requests in the repository Actions settings:
   https://github.com/phip1611/nixos-configs/settings/actions
2. Create a private GitHub App in the account settings:
   https://github.com/settings/apps/new
   - Disable the webhook.
   - Grant repository permissions for `Contents` and `Pull requests`, both
     with read and write access.
   - Generate a private key in the app settings. GitHub downloads the PEM file
     only once; keep it secure and never commit it.
3. Install the app through the GitHub web UI. In the App settings, select
   **Install App**, choose the `phip1611` account, then grant it access to
   **Only select repositories** and select `nixos-configs`.
4. Configure these repository Actions secrets:
   https://github.com/phip1611/nixos-configs/settings/secrets/actions
   - `FLAKE_AUTOUPDATE_APP_ID`: the GitHub App ID.
   - `FLAKE_AUTOUPDATE_APP_PRIVATE_KEY`: the complete contents of the
     downloaded PEM private-key file.


[0] https://github.com/dependabot/dependabot-core/issues/7340
[1] https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md
