# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

/usr/bin/setxkbmap -option "ctrl:nocaps"

export APPS_HOME="$HOME/apps"
export JAVA_HOME="$APPS_HOME/java"
export MAVEN_HOME="$APPS_HOME/maven"
export M2_HOME="$MAVEN_HOME"
export SCALA_HOME="$APPS_HOME/scala"
export PLAY_HOME="$APPS_HOME/play"
export ACTIVATOR_HOME="$APPS_HOME/activator"
export TOMCAT_HOME="$APPS_HOME/tomcat"
export SBT_HOME="$APPS_HOME/sbt"
export GAE_HOME="$APPS_HOME/bin"

export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$SCALA_HOME/bin:$PLAY_HOME/bin:$ACTIVATOR_HOME:$SBT_HOME/bin:$GAE_HOME/bin:$PATH"
