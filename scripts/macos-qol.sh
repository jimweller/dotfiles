#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
  echo "Not macOS. Exiting."
  exit 1
fi

echo "Applying macOS quality-of-life defaults..."

# --- Dock ---

# Position the Dock on the left side of the screen
defaults write com.apple.dock orientation -string left

# Set icon size to smallest (16 pixels)
defaults write com.apple.dock tilesize -int 16

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Set a massive delay before the Dock reappears (effectively always hidden)
defaults write com.apple.dock autohide-delay -float 1000

# Make the hide/show animation instant
defaults write com.apple.dock autohide-time-modifier -float 0

# Hide recent applications section
defaults write com.apple.dock show-recents -bool false

# Minimize windows into their application icon
# defaults write com.apple.dock minimize-to-application -bool true

# Use scale effect for minimizing windows
# defaults write com.apple.dock mineffect -string scale

echo "  Dock configured"

# --- Finder ---

# Default to list view in all windows
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show full POSIX path bar at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar with item count and available space
# defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Search the current folder by default (not the entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Sort folders before files in Finder
# defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show all file extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files (dotfiles) in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

echo "  Finder configured"

# --- Keyboard ---

# Set fast key repeat rate (lower = faster, default 6)
# defaults write NSGlobalDomain KeyRepeat -int 2

# Set short delay before key repeat starts (lower = shorter, default 25)
# defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for accent characters, enable key repeat instead
# defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable automatic spelling correction
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes (replacing -- with em-dash)
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period insertion on double-space
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes (replacing straight quotes with curly quotes)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

echo "  Keyboard configured"

# --- Trackpad ---

# Enable natural scroll direction (content follows finger)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Enable tap-to-click on the trackpad
# defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Enable tap-to-click for the login screen
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

echo "  Trackpad configured"

# --- Screenshots ---

# Save screenshots to ~/tmp instead of Desktop
# defaults write com.apple.screencapture location -string "${HOME}/tmp"

# Save screenshots as PNG
# defaults write com.apple.screencapture type -string "png"

# Disable drop shadow on screenshots
# defaults write com.apple.screencapture disable-shadow -bool true

echo "  Screenshots configured"

# --- Animations ---

# Disable opening/closing window animations
# defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Disable Quick Look panel animation
# defaults write -g QLPanelAnimationDuration -float 0

# Make window resize animation near-instant
# defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

echo "  Animations configured"

# --- Misc ---

# Only show scrollbars when scrolling (not always visible)
# defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Prevent .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Prevent .DS_Store files on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable the "Are you sure you want to open this application?" quarantine dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Auto-quit the print app when all jobs are done
# defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

echo "  Misc configured"

# --- NVRAM: Boot to macOS by default ---
sudo nvram BootPreference=%00
echo "  NVRAM BootPreference set"

# --- Restart affected services ---
killall Dock 2>/dev/null
killall Finder 2>/dev/null
killall SystemUIServer 2>/dev/null

echo "Done. Some changes require logout or restart to take effect."
