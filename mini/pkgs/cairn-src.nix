{
  mkDerivation,
  busybox,
  fetchurl,
}:
mkDerivation {
  name = "cairn-src";
  src = fetchurl {
    url = "https://github.com/bfmhno3/cairn/archive/refs/tags/ch10.tar.gz";
    hash = "sha256-klYYGug+UKdeu0kHZ5o17A7CSIGSImy+3cipzH0ZeY8=";
  };
  installPhase = ''
    mkdir -p "$out/share" "$out/bin"
    cp -r . "$out/share/cairn"
    cat > "$out/bin/cairn-loc" <<EOF
    #!/bin/sh
    PATH=${busybox}/bin
    root=$out/share/cairn
    echo "bin: \$(cat "\$root"/bin/* | wc -l)"
    echo "lib: \$(find "\$root/lib" -type f -exec cat {} + | wc -l)"
    EOF
    chmod +x "$out/bin/cairn-loc"
  '';
}
