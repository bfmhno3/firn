{ writeShellApplication, cairn }:

writeShellApplication {
  name = "cairn-report";
  runtimeInputs = [ cairn ];
  text = ''
    if (($# != 1)); then
      echo 'usage: cairn-report CONFIG' >&2
      exit 2
    fi
    cairn -c "$1" report
  '';
}
