#!/usr/bin/env bash
#
# Import from derivation: `import` a file that does not exist yet, so the
# evaluator has to build it first. Prints the cold run (includes the build),
# then the median of 5 warm runs (derivation already built) next to a plain
# import of a static file with the same content.

set -o errexit
set -o nounset
set -o pipefail

readonly pkgs_nix="${FIRN_ROOT}/nix/pkgs.nix"

#######################################
# Wall time of `nix eval --impure --expr` in milliseconds.
# Arguments:
#   Nix expression.
# Outputs:
#   Writes the elapsed milliseconds to stdout.
#######################################
time_eval() {
  local start end
  start="${EPOCHREALTIME/./}"
  nix eval --impure --expr "$1" >/dev/null
  end="${EPOCHREALTIME/./}"
  echo $(((end - start) / 1000))
}

#######################################
# Median of 5 runs of time_eval.
# Arguments:
#   Nix expression.
# Outputs:
#   Writes the median in milliseconds to stdout.
#######################################
median_eval() {
  for _ in 1 2 3 4 5; do
    time_eval "$1"
  done | sort -n | sed -n 3p
}

# Gen name unique per run: the first IFD really builds.
readonly ifd_expr="
  let pkgs = import ${pkgs_nix} { };
  in import (pkgs.runCommand \"gen-${EPOCHREALTIME/./}\" { } ''
    echo '{ x = 42; }' > \$out
  '')
"
readonly plain_expr="import ${FIRN_ROOT}/lab/ch04/fixtures/gen.nix"
readonly pkgs_only_expr="builtins.seq (import ${pkgs_nix} { }).hello.name (import ${FIRN_ROOT}/lab/ch04/fixtures/gen.nix)"

echo "result: $(nix eval --impure --expr "${ifd_expr}")"
cold_start="${EPOCHREALTIME/./}"
nix eval --impure --expr "${ifd_expr/gen-/gen-cold-}" >/dev/null
cold_end="${EPOCHREALTIME/./}"
echo "ifd cold (builds during evaluation): $(((cold_end - cold_start) / 1000)) ms"
ifd="$(median_eval "${ifd_expr}")"
plain="$(median_eval "${plain_expr}")"
pkgs_only="$(median_eval "${pkgs_only_expr}")"
echo "ifd warm median of 5: ${ifd} ms"
echo "plain import median of 5: ${plain} ms"
echo "plain import after loading nixpkgs median of 5: ${pkgs_only} ms"
echo "ifd / plain-after-nixpkgs: $(awk -v a="${ifd}" -v b="${pkgs_only}" 'BEGIN { printf "%.2f", a / b }')"
