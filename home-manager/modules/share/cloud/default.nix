#
# Cloud related stuff.
#

{
  #imports = fileExplorer.allSubdirs ./.;
  imports = [
    ./aws
    ./k8s
  ];
}
