{
  mkDerivation,
  hello,
  wordfreq,
  cairn-src,
}:
mkDerivation {
  name = "site";
  src = ./site;
  buildInputs = [
    hello
    wordfreq
  ];
  buildPhase = ''
    hello > hello.txt
    wordfreq 5 < ${cairn-src}/share/cairn/README.md > words.txt
    awk '
      /^# /  { print "<h1>" substr($0, 3) "</h1>"; next }
      /^## / { print "<h2>" substr($0, 4) "</h2>"; next }
      /^@[A-Z]+@$/ {
        file = ($0 == "@HELLO@") ? "hello.txt" : "words.txt"
        print "<pre>"
        while ((getline line < file) > 0) print line
        close(file)
        print "</pre>"
        next
      }
      NF { print "<p>" $0 "</p>" }
    ' index.md > index.html
  '';
  installPhase = ''
    install -D index.html "$out/index.html"
  '';
}
