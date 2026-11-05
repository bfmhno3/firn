#!/usr/bin/env bash
#
# Exercise: let a tool write the `src` of pkgs/pebble/package.nix.
# `nix-init --headless --url ... --rev tutorial-v1` can run without prompts,
# but for a Rust project it updates the crates.io git index and that took more
# than four minutes of retries and failed on the machine used for this
# series (spurious network error), so the lab uses `nurl`, which nix-init
# calls for the fetcher anyway. The answer: nurl's fetchFromGitHub block is
# the `src` of the package, character for character.

set -o errexit
set -o nounset
set -o pipefail

pkg="${FIRN_ROOT}/pkgs/pebble/package.nix"

expected="$(nurl https://github.com/bfmhno3/pebble tutorial-v1 2>/dev/null)"
echo "== nurl https://github.com/bfmhno3/pebble tutorial-v1"
echo "${expected}"

# package.nix 里 src 的缩进是两格，去掉缩进、拿掉 "src = " 前缀再比较。
actual="$(sed -n '/^  src = fetchFromGitHub {/,/^  };/p' "${pkg}" \
  | sed -e 's/^  src = //' -e 's/^  //' -e 's/^};$/}/')"
echo
echo "== src block of pkgs/pebble/package.nix"
echo "${actual}"

if [[ "${actual}" == "${expected}" ]]; then
  echo
  echo "same fetcher and hash"
else
  echo "differs from nurl" >&2
  exit 1
fi
