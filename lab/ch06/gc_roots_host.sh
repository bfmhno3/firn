#!/usr/bin/env bash
#
# Host only. Garbage collection starts from the roots; this lists them without
# collecting anything (`--print-roots`). Prints the number of roots, how many
# come from three kinds of source, and one sample line of each kind. Nothing in the
# store is deleted. Note: while scanning, nix-store itself removes stale
# symlinks under /nix/var/nix/gcroots/auto (links whose target is gone).

set -o errexit
set -o nounset
set -o pipefail

roots="$(nix-store --gc --print-roots 2>/dev/null)"
readonly roots
echo "roots: $(wc -l <<<"${roots}")"
echo "by source:"
for pattern in '^"?/proc/' '^"?/nix/var/nix/' '^"?/home/'; do
  printf '  %-20s %s\n' "${pattern}" "$(grep -Ec -- "${pattern}" <<<"${roots}")"
done
echo "samples:"
for pattern in '^"?/proc/' '^"?/nix/var/nix/profiles/' '^"?/nix/var/nix/gcroots/'; do
  grep -E -m 1 -- "${pattern}" <<<"${roots}" | cut -c1-140 || true
done
