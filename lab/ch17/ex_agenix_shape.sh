#!/usr/bin/env bash
#
# Exercise: agenix's model with plain age. A `secrets.nix` maps each secret
# file to the public keys allowed to read it; encryption goes to all of them;
# a machine decrypts with its own SSH host key. Everything happens in LAB_TMP
# with throwaway keys. Prints which keys can decrypt.

set -o errexit
set -o nounset
set -o pipefail

main() {
  cd "${LAB_TMP}"
  local k
  for k in alice host1 mallory; do
    ssh-keygen -q -t ed25519 -N '' -C "${k}" -f "${k}"
  done

  # agenix 的 secrets.nix：文件名 -> 允许读它的公钥。
  cat >secrets.nix <<NIX
let
  alice = "$(cut -d' ' -f1-2 alice.pub)";
  host1 = "$(cut -d' ' -f1-2 host1.pub)";
in
{
  "token.age".publicKeys = [
    alice
    host1
  ];
}
NIX
  echo "== recipients of token.age"
  nix eval --file secrets.nix --apply 'x: builtins.length x."token.age".publicKeys'

  # nix eval 把公钥列表交给 age：一行一个，正是 age -R 要的文件。
  nix eval --raw --file secrets.nix --apply \
    'x: builtins.concatStringsSep "\n" x."token.age".publicKeys' >recipients.txt
  printf '\n' >>recipients.txt
  printf 'correct-horse-battery-staple\n' \
    | age -R recipients.txt -o token.age

  echo "== who can decrypt token.age"
  for k in alice host1 mallory; do
    if age -d -i "${k}" token.age >/dev/null 2>&1; then
      echo "${k}: yes"
    else
      echo "${k}: no"
    fi
  done
  age -d -i host1 token.age | cmp - <(printf 'correct-horse-battery-staple\n')
  [[ "$(age -d -i alice token.age)" == correct-horse-battery-staple ]]
  ! age -d -i mallory token.age >/dev/null 2>&1
}

main "$@"
