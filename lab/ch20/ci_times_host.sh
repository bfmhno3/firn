#!/usr/bin/env bash
#
# Reads the durations of the `check` job of .github/workflows/ci.yml from
# GitHub (`gh run list`, `gh run view`: read-only) for each matrix leg: the
# first successful run (cold caches) and the latest one (warm). Needs `gh`
# logged in. All times are `volatile:`. Before ci.yml has run on GitHub the lab
# prints that there is nothing to read and exits 0.

set -o errexit
set -o nounset
set -o pipefail

readonly REPO="bfmhno3/firn"

#######################################
# Print duration of every job of one run.
# Arguments:
#   Label ("first" or "latest"), run id.
# Outputs:
#   One line per job: "volatile: <label> <job name>: <seconds> s".
#######################################
print_jobs() {
  local label="$1"
  local id="$2"
  gh run view "${id}" -R "${REPO}" --json jobs \
    | jq --raw-output --arg label "${label}" '.jobs[]
      | "volatile: \($label) \(.name): \(
          (.completedAt | fromdate) - (.startedAt | fromdate)) s (\(.conclusion))"'
}

main() {
  local runs
  # Until ci.yml is on the default branch on GitHub, gh answers HTTP 404.
  if ! runs="$(gh run list -R "${REPO}" --workflow ci.yml --status success \
    --limit 100 --json databaseId,createdAt 2>&1)"; then
    echo "no ci.yml run to read: ${runs}"
    return 0
  fi
  if [[ "$(jq length <<<"${runs}")" -eq 0 ]]; then
    echo "no successful ci.yml run yet"
    return 0
  fi
  local first latest
  first="$(jq 'sort_by(.createdAt) | first | .databaseId' <<<"${runs}")"
  latest="$(jq 'sort_by(.createdAt) | last | .databaseId' <<<"${runs}")"
  print_jobs first "${first}"
  print_jobs latest "${latest}"
}

main "$@"
