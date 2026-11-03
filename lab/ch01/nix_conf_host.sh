#!/usr/bin/env bash
#
# Reads this machine's effective Nix settings.

set -o errexit
set -o nounset
set -o pipefail

for key in experimental-features substituters sandbox max-jobs cores \
  trusted-users; do
  printf '%s = ' "${key}"
  nix config show "${key}"
done
printf 'trusted-public-keys count = '
nix config show trusted-public-keys | wc -w
echo '== head -3 /etc/nix/nix.conf'
head -3 /etc/nix/nix.conf
