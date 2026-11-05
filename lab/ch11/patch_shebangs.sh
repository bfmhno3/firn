#!/usr/bin/env bash
#
# patchShebangs in action: the first line of bin/cairn in the fetched source
# and in $out. The source keeps `#!/usr/bin/env bash`; the fixup phase
# rewrote it to the bash from buildInputs (the script is now .cairn-wrapped).

set -o errexit
set -o nounset
set -o pipefail

src="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#cairn.src")"
out="$(nix build --no-link --print-out-paths "${FIRN_ROOT}#cairn")"

echo "src:  $(head -n 1 "${src}/bin/cairn")"
echo "out:  $(head -n 1 "${out}/bin/.cairn-wrapped")"
echo "bash: $(nix eval --raw "${FIRN_ROOT}#cairn.buildInputs" --apply 'bs: (builtins.head bs).name')"
