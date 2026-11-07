#!/usr/bin/env bash
#
# age in four commands: generate an X25519 key, encrypt a file to its public
# key, look at the ciphertext header, decrypt it again. Prints the sizes: the
# ciphertext is the plaintext plus a fixed overhead per recipient.

set -o errexit
set -o nounset
set -o pipefail

main() {
  cd "${LAB_TMP}"
  age-keygen -o key.txt 2>/dev/null
  local pub
  pub="$(age-keygen -y key.txt)"
  echo "volatile: recipient: ${pub}"

  printf 'correct-horse-battery-staple\n' >plain.txt
  age -r "${pub}" -o plain.txt.age plain.txt
  echo "== header of plain.txt.age"
  head -c 21 plain.txt.age
  echo
  sed -n 2p plain.txt.age | cut -d' ' -f1-2
  echo "== sizes (bytes)"
  echo "plain.txt:     $(wc -c <plain.txt)"
  echo "plain.txt.age: $(wc -c <plain.txt.age)"
  echo "key.txt:       $(wc -c <key.txt)"

  age -d -i key.txt -o roundtrip.txt plain.txt.age
  cmp plain.txt roundtrip.txt
  echo "== decrypted"
  cat roundtrip.txt

  echo "== a second key cannot decrypt"
  age-keygen -o other.txt 2>/dev/null
  if age -d -i other.txt plain.txt.age 2>&1 | sed 's/^/volatile: /'; then
    echo "unexpected success" >&2
    return 1
  fi
}

main "$@"
