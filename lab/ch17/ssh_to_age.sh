#!/usr/bin/env bash
#
# NixOS machines already have an ed25519 SSH host key. ssh-to-age turns the
# public half into an age recipient (what goes into .sops.yaml) and the
# private half into an age identity (what sops-nix does at activation when
# sops.age.sshKeyPaths is set). Uses a throwaway key in LAB_TMP, never
# /etc/ssh.

set -o errexit
set -o nounset
set -o pipefail

main() {
  cd "${LAB_TMP}"
  ssh-keygen -q -t ed25519 -N '' -C firn-lab -f host_key
  echo "volatile: ssh public key: $(cut -d' ' -f1-2 host_key.pub)"

  local recipient identity
  recipient="$(ssh-to-age -i host_key.pub)"
  echo "volatile: age recipient: ${recipient}"
  identity="$(ssh-to-age -private-key -i host_key)"
  echo "identity prefix: ${identity:0:15}"

  # 同一把密钥的两个视图必须对得上：用转换出的私钥算回公钥。
  printf '%s\n' "${identity}" >identity.txt
  [[ "$(age-keygen -y identity.txt)" == "${recipient}" ]] || {
    echo "recipient and identity do not match" >&2
    return 1
  }
  echo "age-keygen -y of the converted private key == converted public key"

  printf 'host secret\n' | age -r "${recipient}" -o host.age
  age -d -i identity.txt host.age
}

main "$@"
