#!/usr/bin/env bash
#
# Median of 5 curl requests (`-w '%{time_total}'`) to the SJTU, TUNA and USTC
# mirrors and to cache.nixos.org itself, for two read-only GET requests: the
# cache's nix-cache-info and the .narinfo of the pinned `hello`. Nothing is
# sent but GET; no store path is downloaded. The first request of each URL
# includes the TLS handshake, so one untimed warm-up request precedes the five.
# Latencies depend on the host's network, so every number is `volatile:`.

set -o errexit
set -o nounset
set -o pipefail

readonly RUNS=5
readonly MIRROR_NAMES=(sjtu tuna ustc cache.nixos.org)

#######################################
# Base URL of a mirror.
# Arguments:
#   Mirror name.
#######################################
base_url() {
  case "$1" in
    sjtu) echo "https://mirror.sjtu.edu.cn/nix-channels/store" ;;
    tuna) echo "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ;;
    ustc) echo "https://mirrors.ustc.edu.cn/nix-channels/store" ;;
    cache.nixos.org) echo "https://cache.nixos.org" ;;
  esac
}

#######################################
# Median request time of one URL.
# Arguments:
#   URL.
# Outputs:
#   Writes "<median of RUNS requests> ms (HTTP <status of the last one>)".
#######################################
median_ms() {
  local url="$1"
  local i line code=""
  local -a times=()
  curl --silent --output /dev/null "${url}"
  for ((i = 0; i < RUNS; i++)); do
    line="$(curl --silent --output /dev/null \
      --write-out '%{http_code} %{time_total}' "${url}")"
    code="${line% *}"
    times+=("$(awk -v t="${line#* }" 'BEGIN { printf "%.0f", t * 1000 }')")
  done
  printf '%s ms (HTTP %s)\n' \
    "$(printf '%s\n' "${times[@]}" | sort -n | sed -n "$(((RUNS + 1) / 2))p")" \
    "${code}"
}

main() {
  local out hash name base
  out="$(nix eval --raw --file "${FIRN_ROOT}/nix/pkgs.nix" hello.outPath)"
  hash="$(basename "${out}" | cut -c1-32)"
  for name in "${MIRROR_NAMES[@]}"; do
    base="$(base_url "${name}")"
    echo "volatile: ${name} nix-cache-info median of ${RUNS}:" \
      "$(median_ms "${base}/nix-cache-info")"
    echo "volatile: ${name} hello.narinfo median of ${RUNS}:" \
      "$(median_ms "${base}/${hash}.narinfo")"
  done
}

main "$@"
