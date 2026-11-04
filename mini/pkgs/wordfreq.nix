{ mkDerivation, busybox }:
mkDerivation {
  name = "wordfreq";
  installPhase = ''
    mkdir -p "$out/bin"
    cat > "$out/bin/wordfreq" <<'EOF'
    #!/bin/sh
    # wordfreq [N]: top N words of stdin (default 10) as "<count> <word>".
    PATH=${busybox}/bin
    awk '
      {
        line = tolower($0)
        gsub(/[^a-z]+/, " ", line)
        n = split(line, words, " ")
        for (i = 1; i <= n; i++) count[words[i]]++
      }
      END { for (w in count) print count[w], w }
    ' | sort -k1,1nr -k2,2 | head -n "''${1:-10}"
    EOF
    chmod +x "$out/bin/wordfreq"
  '';
}
