#!/usr/bin/env bash
#
# After the repository was pushed and the publish workflow
# (.github/workflows/flakehub.yml) ran: does the rolling FlakeHub release
# https://flakehub.com/f/bfmhno3/firn/0.1.* lock to the commit of the tag ch19?
# Prints the version string FlakeHub assigned (0.1.<commit count>+rev-<sha>)
# and the locked revision. Exits 1 if the revisions differ and the tag's commit
# is not an ancestor of the release (a later push moved the rolling release on,
# which is fine). If the flake is not on FlakeHub yet or the tag ch19 does not
# exist yet, prints why and exits 0. Needs the network.

set -o errexit
set -o nounset
set -o pipefail

readonly REF='https://flakehub.com/f/bfmhno3/firn/0.1.*'

main() {
  local meta
  if ! meta="$(nix flake metadata --json "${REF}" 2>&1)"; then
    echo "volatile: not resolvable yet: $(grep -m 1 'HTTP error' <<<"${meta}" \
      | sed 's/.*\(HTTP error [0-9]*\).*/\1/')"
    return 0
  fi
  local url rev
  url="$(jq --raw-output '.locked.url' <<<"${meta}")"
  rev="$(jq --raw-output '.locked.rev' <<<"${meta}")"
  echo "volatile: locked url: ${url}"
  echo "volatile: version: $(sed -E 's#.*/firn/([^/]*)/.*#\1#' <<<"${url}" \
    | sed 's/%2B/+/')"
  echo "volatile: locked rev: ${rev}"

  local tag_rev
  if ! tag_rev="$(git -C "${FIRN_ROOT}" rev-parse 'ch19^{commit}' \
    2>/dev/null)"; then
    echo "volatile: tag ch19 does not exist yet"
    return 0
  fi
  echo "ch19 commit: ${tag_rev}"
  if [[ "${rev}" == "${tag_rev}" ]]; then
    echo "match: the rolling release is the ch19 commit"
  elif git -C "${FIRN_ROOT}" merge-base --is-ancestor "${tag_rev}" "${rev}" \
    2>/dev/null; then
    echo "volatile: the rolling release moved past ch19"
  else
    echo "mismatch: ${rev} is not ch19 or a descendant of it" >&2
    return 1
  fi
}

main "$@"
