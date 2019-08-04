#!/bin/bash

PARAMS=( "$@")
PARAMS="${PARAMS[@]:2}"

TEMP_SCRIPT=$TMPDIR
TEMP_SCRIPT+="script.sh"
/bin/cat <<EOM >$TEMP_SCRIPT
cd "$1"
SCRIPT="$2"

clear
"\$SCRIPT" $PARAMS
EOM

chmod +x $TEMP_SCRIPT
echo "$TEMP_SCRIPT"

osascript <<END
tell application "Terminal" 
    set shell to do script ". $TEMP_SCRIPT"
    activate in shell
end tell
END