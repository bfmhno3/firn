#!/usr/bin/env bash
#
# The same expressions through `nix eval` and `nix-instantiate --eval`.
# Without --strict, nix-instantiate prints a lazy attribute set as "<CODE>".

set -o errexit
set -o nounset
set -o pipefail

#######################################
# Print a command with its last argument single-quoted, then run it.
#######################################
show() {
  printf '$ %s '"'%s'"'\n' "${*:1:$#-1}" "${!#}"
  "$@"
}

attrs='{ a = 1 + 1; b = "x"; }'
list='[ (1 + 1) "x" ]'

show nix eval --expr "${attrs}"
show nix-instantiate --eval --expr "${attrs}"
show nix-instantiate --eval --strict --expr "${attrs}"
show nix-instantiate --eval --strict --json --expr "${attrs}"
show nix eval --json --expr "${attrs}"
show nix eval --expr "${list}"
show nix-instantiate --eval --expr "${list}"
show nix-instantiate --eval --strict --expr "${list}"
show nix eval --expr '1 + 1'
show nix-instantiate --eval --expr '1 + 1'
show nix eval --raw --expr '"no quotes"'
