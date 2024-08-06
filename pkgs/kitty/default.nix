#
# The fast, feature-rich, GPU based terminal emulator.
# src: https://github.com/kovidgoyal/kitty
#
# Creating my nix package myself because the one provided by the official nixpkgs is not working well
# in non-NixOS, as kitty is using OpenGL.
# src:
# - https://discourse.nixos.org/t/egl-program-is-unusable-when-built-with-nix/5976/2
# - https://github.com/NixOS/nixpkgs/issues/290847
# - https://github.com/NixOS/nixpkgs/issues/9415
#

{ lib, stdenvNoCC, xz }: stdenvNoCC.mkDerivation rec {
  pname = "kitty";
  version = "0.35.2";
  # TODO: Support other systems using stdenvNoCC.isx86_64 | stdenvNoCC.isDarwin?
  system = "x86_64";

  src = builtins.fetchurl {
    url = "https://github.com/kovidgoyal/kitty/releases/download/v${version}/kitty-${version}-${system}.txz";
    sha256 = "1k1sv7g19gg9r9g5qyv4pszvpdkx6yk612cma251g5als3nb36x4";
  };

  nativeBuildInputs = [ xz ];

  outputs = [ "out" "kitten" ];
  
  unpackPhase = ''
    xz -d < ${src} | tar xvf -
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"
    mkdir -p "$kitten/bin"

    # We need to add everything from the tarball because it contains some dependencies used by the binary.
    cp -r {bin,share} "$out"
    ls -alh lib
    # libpython3.12.so.1.0 is in conflict with python3.
    for f in $(find lib -depth 1 -type f | grep -v libpython3.12.so.1.0); do
      cp "$f" "$out/lib"
    done
    for f in lib/*/; do
      echo $f
      cp -r "$f" "$out/lib"
    done
    cp bin/kitten "$kitten/bin/kitten"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern, hackable, featureful, OpenGL based terminal emulator";
    homepage = "https://github.com/kovidgoyal/kitty";
    # list of nix licenses available here: https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "kitty";
  };
}
