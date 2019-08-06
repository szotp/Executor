# title: Install .ipa
# extensions: ipa

IPA=$1

if [[ -d $IPA ]]; then
    IPA=$(ls -t *.ipa | head -1)
fi

ideviceinstaller -i $IPA
echo "Exiting..."
sleep 2
exit
