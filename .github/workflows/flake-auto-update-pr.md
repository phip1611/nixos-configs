# Flake Auto Update via GitHub Actions

As long as Dependabot doesn't support Nix flakes [0], this CI action updates the
flake once per day. It is scheduled by GitHub during Midnight.

The action creates a new PR. To be able to run the normal CI pipeline for that
PR, we need a dedicated access token for the job [1].

1. Allow workflows to create PRs: https://github.com/phip1611/nixos-configs/settings/actions
2. Get Token for Workflow
     - https://github.com/settings/personal-access-tokens
     - Contents: r/w
     - Pull Requests: r/w
3. Configure Token as Workflow Secret
     - https://github.com/phip1611/nixos-configs/settings/secrets/actions


[0] https://github.com/dependabot/dependabot-core/issues/7340

[1] https://github.com/peter-evans/create-pull-request/issues/48
