#!/usr/bin/env bash
#
# How far an overlay reaches. `nix build --dry-run` for firn-hello under
# three pkgs: unchanged, an overlay that touches `hello` (not a dependency of
# firn-hello), and an overlay that touches `zlib` (a build input of firn-hello
# and of much of the toolchain). The count of derivations that `will be built`
# depends on what the binary caches have, so numbers are marked `volatile:`;
# which names appear in the list is stable. Needs the binary cache to tell what
# is already substitutable; when it is unreachable the lab says so and stops.
# The unchanged and the hello cases print 0 because firn-hello itself is in
# the local store after the first build (it is not in any binary cache).

set -o errexit
set -o nounset
set -o pipefail

if ! curl --silent --head --max-time 10 --output /dev/null --fail \
  https://cache.nixos.org/nix-cache-info; then
  echo "offline: cache.nixos.org unreachable, the counts would not mean anything"
  exit 0
fi

fixtures="${FIRN_ROOT}/lab/ch10/fixtures"
readonly fixtures

#######################################
# Dry-run firn-hello from a pkgs file and print the "will be built" part.
# Arguments:
#   File that evaluates to a package set.
# Outputs:
#   The .drv names that would be built, one per line, sorted, to stdout.
#######################################
would_build() {
  nix build --dry-run --file "$1" firn-hello 2>&1 \
    | awk '/will be built/ { f = 1; next } /^(these|this) / { f = 0 } f' \
    | sed 's|^ *||; s|^/nix/store/[a-z0-9]*-||; s|\.drv$||' \
    | sort
}

#######################################
# Print the dry-run summary for one package set.
# Arguments:
#   Heading, file that evaluates to a package set.
# Outputs:
#   Count of derivations to build and which interesting names are among them.
#######################################
report() {
  local label="$1"
  local file="$2"
  local names
  names="$(would_build "${file}")"
  echo "== ${label}"
  if [[ -z "${names}" ]]; then
    echo "volatile: 0 derivations will be built"
    return
  fi
  echo "volatile: $(wc -l <<<"${names}") derivations will be built"
  for pattern in '^zlib-' '^firn-hello-' '^glibc-[0-9]' '^gcc-[0-9]' '^hello-'; do
    if grep -q "${pattern}" <<<"${names}"; then
      echo "  in the list: $(grep "${pattern}" <<<"${names}" | sort -u | paste -sd' ' -)"
    else
      echo "  not in the list: ${pattern}"
    fi
  done
}

report "no extra overlay (nix/pkgs.nix)" "${FIRN_ROOT}/nix/pkgs.nix"
echo
report "overlay changes hello (unrelated)" "${fixtures}/hello_tweak.nix"
echo
report "overlay changes zlib" "${fixtures}/zlib_tweak.nix"
