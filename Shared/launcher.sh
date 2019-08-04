#!/bin/bash

A=( "$@" )
B="${A[@]:2}"

osascript <<END
tell application "Terminal"
set shell to do script "cd \"$1\""
do script "\"$2\" $B" in shell
activate in shell
do script "clear" in shell
end tell
END
