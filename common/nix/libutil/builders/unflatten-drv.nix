# Unflattens a derivation. If a derivation produces a single file instead of a
# directory, this derivation symlinks the artifact to a result directory.

{
  runCommandLocal,
}:

{
  # Derivation to flatten.
  drv,
  # Artifact path inside the derivation.
  artifactPath ? drv.name,
  # Name of the new derivation.
  name ? "unflattened-${drv.name}",
}:

runCommandLocal name
  {
    passthru = drv.passthru;
  }
  ''
    set -euo pipefail

    mkdir -p $out/$(dirname ${artifactPath})

    if [ -e "${drv}" ] && { [ -f "${drv}" ] || [ -L "${drv}" ]; }
    then
        # exists, and is a regular file or a symbolic link to one
        ln -s ${drv} $out/${artifactPath}
    else
        echo "${drv} is not a file (or a link to one)"
        exit 1
    fi
  ''
