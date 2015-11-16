#!/bin/sh
# http://askubuntu.com/questions/462021/how-do-i-turn-caps-lock-into-an-extra-control-key#answer-521734
# -----------------------------------------
# To swap the keys go:
# Xubuntu → Settings Manager → Session and Startup
# Then in the Sessions and Startup configurator go
# Application Autostart (tab at the top) → Add (bottom button)
# Now on the Add Application screen
#   Name: Control and CapsLk swap
#   Description: Swap the two keys
#   Command: /usr/bin/setxkbmap -option "ctrl:nocaps"
# -----------------------------------------

/usr/bin/setxkbmap -option "ctrl:nocaps"

# This one will swap ctrl and capslock
#/usr/bin/setxkbmap -option "ctrl:swapcaps"

