final: _prev: {
  firn-hello = final.callPackage ../pkgs/firn-hello/package.nix { };
  cairn = final.callPackage ../pkgs/cairn/package.nix { };
  sift = final.callPackage ../pkgs/sift/package.nix { };
  pebble = final.callPackage ../pkgs/pebble/package.nix { };
  firn-tools = final.callPackage ../pkgs/firn-tools/package.nix { };
  cairn-report = final.callPackage ../pkgs/cairn-report/package.nix { };
}
