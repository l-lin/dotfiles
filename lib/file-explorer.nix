# Shamelessly copied from https://github.com/Evertras/nix-systems/blob/0964933c095ffbff428d0956c1be7d2fa7bdd3f1/shared/everlib/default.nix
{ lib }: with lib; {
  # return all subdirectories
  allSubdirs = rootPath:
    let
      readset = builtins.readDir rootPath;
      dirset = filterAttrs (_: type: type == "directory") readset;
      dirs = map (path.append rootPath) (builtins.attrNames dirset);
    in dirs;
}
