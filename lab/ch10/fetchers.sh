#!/usr/bin/env bash
#
# The fixed-output fetchers against bfmhno3/cairn at tag ch10 (commit
# 3febd7b1a00b7dcbb94d6c6258d38327e3bb24d1): fetchurl (a file, and GitHub's
# tarball as a file), fetchFromGitHub and fetchgit (the unpacked tree). Shows
# the hash mode of each FOD (flat or nar), the lib.fakeHash workflow (the error
# prints the real hash), what nurl and nix-prefetch-url --unpack print, and
# `nix hash convert` from nix32 to SRI. The hashes are pinned in
# fixtures/fetchers.nix. Needs github.com; when it is unreachable the lab
# says so and stops, and the pinned hashes stay valid for a later run.

set -o errexit
set -o nounset
set -o pipefail

readonly rev=3febd7b1a00b7dcbb94d6c6258d38327e3bb24d1
readonly fixture="${FIRN_ROOT}/lab/ch10/fixtures/fetchers.nix"

if ! git ls-remote --exit-code https://github.com/bfmhno3/cairn \
  "refs/tags/ch10" >/dev/null 2>&1; then
  echo "offline: github.com unreachable, skipping; hashes in fixtures/fetchers.nix are for tag ch10 (${rev})"
  exit 0
fi

echo "== tag ch10 of bfmhno3/cairn"
git ls-remote https://github.com/bfmhno3/cairn "refs/tags/ch10^{}"

echo
echo "== build the four FODs (name, hash mode, hash)"
for attr in installSh tarball fromGitHub fromGit; do
  nix build --no-link --file "${fixture}" "${attr}"
  drv="$(nix eval --raw --file "${fixture}" "${attr}.drvPath")"
  nix derivation show "${drv}" \
    | jq -r --arg attr "${attr}" \
      '.derivations[].outputs.out | "\($attr): \(.method) \(.hash)"'
done

echo
echo "== the fakeHash workflow: lib.fakeHash makes the build fail and print the real hash"
nix build --no-link --file "${fixture}" --arg fake true fromGitHub 2>&1 \
  | grep -E '^ +(specified|got):' | sed 's/^ *//' || true

echo
echo "== nurl https://github.com/bfmhno3/cairn ch10"
if command -v nurl >/dev/null; then
  nurl https://github.com/bfmhno3/cairn ch10 2>/dev/null
  echo
else
  echo "nurl not on PATH (run inside nix develop)"
fi

echo
echo "== nix-prefetch-url --unpack (prints nix32), then nix hash convert to SRI"
nix32="$(nix-prefetch-url --unpack \
  https://github.com/bfmhno3/cairn/archive/refs/tags/ch10.tar.gz 2>/dev/null)"
readonly nix32
echo "nix32: ${nix32}"
sri="$(nix hash convert --hash-algo sha256 --to sri "${nix32}")"
readonly sri
echo "sri:   ${sri}"
want="$(nix eval --raw --file "${fixture}" --apply 'p: p.drvAttrs.outputHash' fromGitHub)"
readonly want
if [[ "${sri}" == "${want}" ]]; then
  echo "matches the fetchFromGitHub hash"
else
  echo "DIFFERENT from ${want}"
  exit 1
fi
