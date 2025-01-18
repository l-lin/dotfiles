#
# Terminal emulators.
#

{ userSettings, ... }: {
  imports = [
    # TODO: Remove me once I'm either convinced to use Ghostty or rollbacked to kitty.
    ./kitty

    (./. + "/${userSettings.term}")
  ];
}
