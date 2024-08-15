#
# Cloud related stuff.
#

{
  imports = [ ./aws ];

  # HACK: DISABLED because I don't need terraform and k8s yet.
  # imports = fileExplorer.allSubdirs ./.;
}
