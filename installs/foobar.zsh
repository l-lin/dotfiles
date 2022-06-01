#!/usr/bin/env zsh

setopt EXTENDED_GLOB
input='ssh -Y user@host some command'
prefix='ssh( [^ ]##)#'
print ${input#$~prefix }
