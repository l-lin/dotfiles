#
# A fork of Firefox, focused on keeping the Open, Private and Sustainable Web alive, built in Japan.
# src: https://floorp.app/
#
# Creating my nix package myself because the one provided by official nixpkgs does not seem to have correct dependencies.
# Derivation that just download the tarball, extract to the nix store.
# FIXME: Not working yet! I can launch floorp, but it's not available system-wide and the configuration set at
# home-manager/modules/browser/floorp/default.nix is not applied.
#

{ lib, stdenvNoCC }: stdenvNoCC.mkDerivation rec {
  pname = "floorp";
  version = "11.18.0";
  # TODO: Support other systems using stdenvNoCC.isx86_64 | stdenvNoCC.isDarwin?
  system = "linux-x86_64";

  src = builtins.fetchurl {
    url = "https://github.com/Floorp-Projects/Floorp/releases/download/v${version}/floorp-${version}.${system}.tar.bz2";
    sha256 = "15x4i5kwdz1ywaxfspk8y17xx59sbqikjxwjylc92jrmhl5ljm6x";
  };

  outputs = [ "out" ];

  unpackPhase = ''
    tar -xjf ${src}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r floorp/* "$out/bin"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Fork of Firefox, focused on keeping the Open, Private and Sustainable Web alive, built in Japan";
    homepage = "https://floorp.app/";
    # list of nix licenses available here: https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix
    license = lib.licenses.mpl20;
    platforms = platforms.unix;
    mainProgram = "floorp";
  };
}

