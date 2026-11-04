{
  mkDerivation,
  busybox,
  greeting,
}:
mkDerivation {
  name = "hello";
  installPhase = ''
    mkdir -p "$out/bin"
    printf '%s\n' '#!/bin/sh' '${busybox}/bin/cat ${greeting}/share/greeting.txt' \
      > "$out/bin/hello"
    chmod +x "$out/bin/hello"
  '';
}
