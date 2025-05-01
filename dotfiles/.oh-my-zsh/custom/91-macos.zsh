dockrestart() 
{
    defaults write com.apple.dock autohide-time-modifier -int 0
    defaults write com.apple.dock autohide-delay -float 10000
    killall Dock
}

btrestart()
{
    sudo pkill bluetoothd
}
