#!/usr/bin/env bash
#
# patchShebangs in action: the first line of bin/cairn in the fetched source
# and in $out. The source keeps `#!/usr/bin/env bash`; the script in $out
# (now .cairn-wrapped) points at the bash from buildInputs.
# Who rewrote it depends on doCheck: with doCheck = true the preCheck hook of
# pkgs/cairn/package.nix already ran patchShebangs on the source tree, so the
# fixup phase finds nothing to change. With doCheck = false (an overrideAttrs
# variant) the fixup phase does the rewrite. The build logs show the phase.

set -o errexit
set -o nounset
set -o pipefail

#######################################
# Print the build phase that rewrote the shebang of bin/cairn.
# Arguments:
#   Installable arguments for `nix log` / `nix build`.
# Outputs:
#   Writes one "  <phase>: bin/cairn rewritten" line per rewrite.
#######################################
rewrite_phase() {
  local log="${LAB_TMP}/phase.log"
  if ! nix log "$@" >"${log}" 2>/dev/null; then
    echo "volatile: no local build log, rebuilding with --rebuild"
    nix build --no-link --rebuild -L "$@" >"${log}" 2>&1
  fi
  awk '
    /Running phase:/ { phase = $NF }
    /interpreter directive changed/ { print "  " phase ": bin/cairn rewritten" }
  ' "${log}"
}

src="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#cairn.src")"
out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#cairn")"

echo "src:  $(head -n 1 "${src}/bin/cairn")"
echo "out:  $(head -n 1 "${out}/bin/.cairn-wrapped")"
echo "bash: $(nix eval --raw "${FIRN_ROOT}#cairn.buildInputs" --apply 'bs: (builtins.head bs).name')"

echo
echo "== doCheck = true (package.nix)"
rewrite_phase "${FIRN_ROOT}#cairn"

echo
echo "== doCheck = false (overrideAttrs)"
cat >"${LAB_TMP}/nocheck.nix" <<NIX
(import ${FIRN_ROOT}/nix/pkgs.nix { }).cairn.overrideAttrs { doCheck = false; }
NIX
nix build --no-link --impure --file "${LAB_TMP}/nocheck.nix"
rewrite_phase --impure --file "${LAB_TMP}/nocheck.nix"
