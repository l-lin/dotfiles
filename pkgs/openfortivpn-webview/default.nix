#
# Application to perform the SAML single sign-on and easily retrieve the `SVPNCOOKIE` needed by openfortivpn.
# src: https://github.com/gm-vm/openfortivpn-webview
#

# We are using stdenvNoCC because we don't need the C compiler.
# See https://discourse.nixos.org/t/smaller-stdenv-for-shells/28970 for more information about smaller stdenv.
{ stdenvNoCC, lib }: stdenvNoCC.mkDerivation rec {
  pname = "openfortivpn-webview";
  version = "1.2.0";

  src = builtins.fetchTarball {
    url = "https://github.com/gm-vm/openfortivpn-webview/releases/download/v${version}-electron/openfortivpn-webview-${version}.tar.xz";
    sha256 = "050vsb60zk8q398rzgl0glz3a2jpfghllmcnm1gjfxm9i7n2ddsa";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    # We need to add everything from the tarball because it contains some dependencies used by the binary, like `libffmpeg.so`.
    cp -r * $out/bin
  '';

  meta = with lib; {
    description = "OpenfortiVPN webview to get the cookie";
    homepage = "https://github.com/gm-vm/openfortivpn-webview";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "openfortivpn-webview";
  };
}
