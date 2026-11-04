{
  mkDerivation,
  text ? "Hello from mini",
}:
mkDerivation {
  name = "greeting";
  inherit text;
  installPhase = ''
    mkdir -p "$out/share"
    printf '%s\n' "$text" > "$out/share/greeting.txt"
  '';
}
