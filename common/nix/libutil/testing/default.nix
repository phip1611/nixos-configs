# Helper utilities for testing.

{
  ansi,
  runCommandLocal,
}:

{
  # Helper that transforms a bash condition to a succeeding or failing
  # derivation.
  bashCondToDrv =
    testName: bashCond:
    runCommandLocal "bash-cond-to-drv-${testName}"
      {
        nativeBuildInputs = [ ansi ];
      }
      ''
        # Bash strict mode.
        set -euo pipefail

        set +e
        if [[ ${bashCond} ]]; then
          mkdir $out
          exit 0
        fi
        set -e

        echo -e "$(ansi bold)$(ansi red)Condition '${bashCond}' for test '${testName}' not met!$(ansi reset)"
        exit 1
      '';
}
