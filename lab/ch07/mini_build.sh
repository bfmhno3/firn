#!/usr/bin/env bash
#
# Builds every package of the mini set (except nondeterministic, the chapter 20
# package that is not reproducible on purpose) through the flake output
# legacyPackages.<system>.mini and prints each closure with `nix path-info
# -rS`. Exits 1 if a closure contains anything but the seed busybox and mini
# paths (that is, a path whose name is not one of the mini package names).

set -o errexit
set -o nounset
set -o pipefail

system="$(nix eval --raw --impure --expr builtins.currentSystem)"
readonly system
readonly mini="${FIRN_ROOT}#legacyPackages.${system}.mini"

# shellcheck disable=SC2016 # the Nix expression is not for this shell
readarray -t names < <(nix eval --json "${mini}" --apply \
  'm: builtins.filter (n: n != "busybox" && n != "nondeterministic" && (m.${n}.type or "") == "derivation") (builtins.attrNames m)' \
  | jq -r '.[]')

pattern='^/nix/store/[0-9a-z]{32}-(busybox-static-[^/]*|'
pattern+="$(printf '%s|' "${names[@]}")"
pattern="${pattern%|})\$"
readonly pattern

status=0
for name in "${names[@]}"; do
  out="$(nix build --no-link --print-out-paths "${mini}.${name}")"
  echo "== ${name}: ${out}"
  nix path-info -rS "${out}"
  while read -r path _; do
    if [[ ! "${path}" =~ ${pattern} ]]; then
      echo "unexpected path in closure of ${name}: ${path}" >&2
      status=1
    fi
  done < <(nix path-info -rS "${out}")
done
exit "${status}"
