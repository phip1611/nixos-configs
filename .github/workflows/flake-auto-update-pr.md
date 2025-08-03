# Flake Auto Update via GitHub Actions

As long as Dependabot doesn't support Nix flakes, this CI action updates the
flake once per day. It is scheduled by GitHub during Midnight.

The action creates a new PR. To be able to run the normal CI pipeline for that
PR, we need a dedicated access token for the job [0].

1. Get token
     - https://github.com/settings/personal-access-tokens
     - Contents: r/w
     - Pull Requests: r/w
2. Configure Token as Workflow Secret
     - https://github.com/phip1611/nixos-configs/settings/secrets/actions


[0] https://github.com/peter-evans/create-pull-request/issues/48
