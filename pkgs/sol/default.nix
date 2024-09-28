#
# A de-minifier (formatter, exploder, beautifier) for shell one-liners.
# src: https://github.com/noperator/sol
#

{ lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "sol";
  version = "main";

  src = fetchFromGitHub {
    owner = "noperator";
    repo = pname;
    rev = "${version}";
    hash = "sha256-0k/LdWWBBxGDtrnkG69lctvPdwie8s3ckICCZ4ERa2M=";
  };

  vendorHash = "sha256-syWp/8JG2ikzvTrin9UfLPf7YEFvz3P0N2QzPDklkWg=";

  ldflags = [
    "-s"
    "-w"
    "-X"
    "main.version=${version}"
  ];

  meta = with lib; {
    description = " A de-minifier (formatter, exploder, beautifier) for shell one-liners ";
    homepage = "https://github.com/noperator/sol";
    license = licenses.mit;
    mainProgram = "sol";
  };
}
