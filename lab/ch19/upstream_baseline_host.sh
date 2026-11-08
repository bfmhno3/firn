#!/usr/bin/env bash
#
# Baseline for the Determinate VM test: the same flake (outputs = _: { x = 1; })
# next to a 512 MiB random blob.bin, evaluated with upstream Nix five times,
# each time from a fresh copy of the directory. Prints the host's `nix
# --version`, first and median wall time of `nix eval path:<copy>#x`, and the
# size of the source path Nix copied into the store. That path is deleted at
# the end with `nix store delete <path>`; it is the only store path this script
# removes. Host only: it writes 6 x 512 MiB into LAB_TMP and 512 MiB into the
# store.

set -o errexit
set -o nounset
set -o pipefail

readonly RUNS=5

#######################################
# Print an error message to stderr.
# Arguments:
#   Message text.
#######################################
err() {
  printf 'upstream_baseline_host.sh: %s\n' "$*" >&2
}

#######################################
# Time one command in milliseconds.
# Arguments:
#   Command and arguments.
# Outputs:
#   Writes the elapsed milliseconds to stdout.
#######################################
time_ms() {
  local start end
  start="$(date +%s%N)"
  "$@" >/dev/null
  end="$(date +%s%N)"
  echo $(((end - start) / 1000000))
}

#######################################
# Median of the numbers on stdin.
#######################################
median() {
  sort -n | sed -n "$(((RUNS + 1) / 2))p"
}

main() {
  echo "nix: $(nix --version)"
  local big="${LAB_TMP}/big"
  mkdir "${big}"
  echo '{ outputs = _: { x = 1; }; }' >"${big}/flake.nix"
  dd if=/dev/urandom of="${big}/blob.bin" bs=1M count=512 status=none

  local -a times=()
  local i copy
  for ((i = 0; i < RUNS; i++)); do
    copy="${LAB_TMP}/big-${i}"
    cp -r "${big}" "${copy}"
    times+=("$(time_ms nix eval "path:${copy}#x")")
  done
  echo "volatile: first eval: ${times[0]} ms"
  echo "volatile: median of ${RUNS}: $(printf '%s\n' "${times[@]}" | median) ms"

  # The copy Nix made of the source tree: the same path for every fresh copy
  # of the same content.
  local store_path
  store_path="$(nix flake metadata --json "path:${LAB_TMP}/big-0" \
    | jq --raw-output '.path')" || {
    err "cannot read the flake's store path"
    return 1
  }
  if [[ "${store_path}" != /nix/store/* ]]; then
    err "unexpected store path: ${store_path}"
    return 1
  fi
  echo "source path size: $(du --summarize --block-size=1M "${store_path}" \
    | cut -f1) MiB"
  nix store delete "${store_path}"
  if [[ -e "${store_path}" ]]; then
    err "store path still exists after nix store delete"
    return 1
  fi
  echo "store path deleted"
}

main "$@"
