#!/usr/bin/env bash
#
# Exercise: install Determinate Nix with the Determinate Nix Installer inside a
# throwaway Ubuntu container (`docker run --rm`, `--init none --no-confirm`,
# as the installer's README prescribes for containers without systemd), then
# print `nix --version` and the keys of the installation receipt
# /nix/receipt.json. The container never touches the host's /nix. The whole
# run is limited to TIMEOUT seconds. If Docker or its network fails (image
# pull, apt, the installer download), the failure is the answer: the script
# prints the exit status and the end of the output, and still exits 0.
# Host only: needs Docker and the network.

set -o errexit
set -o nounset
set -o pipefail

readonly IMAGE=ubuntu:24.04
readonly TIMEOUT=600

# The script that runs inside the container.
INNER="$(
  cat <<'EOF'
set -o errexit
set -o nounset
set -o pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq curl ca-certificates jq >/dev/null
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix \
  | sh -s -- install linux --init none --no-confirm >/tmp/install.log 2>&1 || {
  tail -n 20 /tmp/install.log
  exit 1
}
export PATH="${PATH}:/nix/var/nix/profiles/default/bin"
echo "nix --version: $(nix --version)"
echo "receipt keys: $(jq --compact-output 'keys' /nix/receipt.json)"
echo "action count: $(jq '.actions | length' /nix/receipt.json)"
echo "uninstaller: $(ls /nix/nix-installer)"
EOF
)"
readonly INNER

main() {
  local out status=0
  out="$(
    timeout "${TIMEOUT}" docker run --rm "${IMAGE}" bash -c "${INNER}" 2>&1
  )" || status=$?
  if ((status == 0)); then
    printf '%s\n' "${out}"
  else
    echo "volatile: docker run failed with exit status ${status}"
    printf '%s\n' "${out}" | tail -n 10 | sed 's/^/volatile: /'
  fi
}

main "$@"
