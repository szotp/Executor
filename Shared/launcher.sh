#!/bin/bash

A=( "$@")
B="${A[@]:2}"
EXECUTE='$EXECUTE'

osascript <<END
tell application "Terminal" 
    set shell to do script "cd \"$1\";EXECUTE=\"$2\";clear"
    activate in shell
    do script "\"$EXECUTE\" $B" in shell
end tell
END
