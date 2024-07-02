# Shamelessly copied and adapted from:
# https://github.com/Evertras/nix-systems/blob/0964933c095ffbff428d0956c1be7d2fa7bdd3f1/shared/everlib/default.nix
{ lib }: with lib; {
  # Return all subdirectories excluding specified folders.
  allSubdirs = rootPath:
    let
      readset = builtins.readDir rootPath;
      dirset = filterAttrs (_: type: type == "directory") readset;
      dirs = map (path: "${rootPath}/${path}") (builtins.attrNames dirset);
      filteredDirs = filter (dir: !(any (name: dir == "${rootPath}/${name}") [ ".config" ".local" "pictures" "hosts" "scripts" ])) dirs;
    in filteredDirs;
}
