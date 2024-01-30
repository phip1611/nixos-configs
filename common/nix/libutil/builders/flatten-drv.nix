# Flattens a derivation. If a derivation produces a directory instead of a
# single file, this derivation symlinks the artifact directly as result.

{ runCommandLocal
}:

{
  # Derivation to flatten.
  drv
  # New artifact path inside the derivation.
, artifactPath ? drv.name
  # Name of the new derivation.
, name ? "flattened-${drv.name}"
}:

runCommandLocal name
{
  passthru = drv.passthru;
} ''
  set -euo pipefail

  ln -s "${drv}/${artifactPath}" $out
''
