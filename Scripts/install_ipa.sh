SCRIPT_NAME='Install IPA'
SCRIPT_EXTENSIONS='ipa'

IPA=$1

if [[ -d $IPA ]]; then
    IPA=$(ls -t *.ipa | head -1)
fi

ideviceinstaller -i $IPA
