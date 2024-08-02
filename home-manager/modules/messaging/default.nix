#
# Messaging tools.
#

{ userSettings, ... }: {
  imports = [ ./${userSettings.messaging} ];
}
