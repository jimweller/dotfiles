dockrestart() 
{
  # Set Dock's position to the left side of the screen
  defaults write com.apple.dock orientation -string left

  # Set the icon size to its smallest value (16 pixels)
  defaults write com.apple.dock tilesize -int 16

  # Turn on the autohide feature
  defaults write com.apple.dock autohide -bool true

  # Set a massive delay (in seconds) before the Dock shows up
  # This is the "always hide" trick
  defaults write com.apple.dock autohide-delay -float 1000

  # Optional: Make the hide/show animation instant
  defaults write com.apple.dock autohide-time-modifier -float 0

  # Important: Restart the Dock to apply all the changes
  killall Dock
}

btrestart()
{
    sudo pkill bluetoothd
}
