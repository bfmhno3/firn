#!/usr/bin/env bash
#
# sops with a temporary .sops.yaml: the creation rule picks the age recipient,
# `sops --encrypt` encrypts the values but leaves the keys readable, and
# `sops --decrypt` gives the original file back. Prints the structure of the
# encrypted YAML with the random parts (ciphertext, iv, tag, mac, age stanza)
# elided.

set -o errexit
set -o nounset
set -o pipefail

main() {
  cd "${LAB_TMP}"
  age-keygen -o key.txt 2>/dev/null
  local pub
  pub="$(age-keygen -y key.txt)"
  cat >.sops.yaml <<YAML
creation_rules:
  - path_regex: secrets\.yaml$
    age: ${pub}
YAML
  cat >secrets.yaml <<'YAML'
firn:
  token: correct-horse-battery-staple
  port: 8080
YAML
  cp secrets.yaml plain.yaml

  sops --encrypt --in-place secrets.yaml
  echo "== encrypted secrets.yaml (random parts elided)"
  sed -E \
    -e 's/ENC\[AES256_GCM,data:[^,]*,iv:[^,]*,tag:[^,]*,type:([a-z]+)\]/ENC[AES256_GCM,data:...,type:\1]/' \
    -e '/^            [A-Za-z0-9+\/=]+$/d' \
    -e 's/(recipient: ).*/\1<age public key>/' \
    -e 's/(lastmodified: ).*/\1<time>/' \
    -e 's/(mac: ).*/\1ENC[AES256_GCM,data:...]/' \
    secrets.yaml

  echo "== plaintext leaks?"
  if grep -q 'correct-horse-battery-staple' secrets.yaml; then
    echo "plaintext found in the encrypted file" >&2
    return 1
  fi
  echo none

  echo "== sops --decrypt"
  SOPS_AGE_KEY_FILE=key.txt sops --decrypt secrets.yaml | tee decrypted.yaml
  # sops 重新缩进了 YAML（2 格变 4 格），内容相同，所以忽略空白。
  diff -w plain.yaml decrypted.yaml
}

main "$@"
