#!/bin/bash

## Dock
# Do not show recently
defaults write com.apple.dock "show-recents" -bool "false"

killall Dock

## Screenshots
# Set default screenshot format to PNG
defaults write com.apple.screencapture "type" -string "png"

## Safari
# Show full website URL
defaults write com.apple.Safari "ShowFullURLInSmartSearchField" -bool "true"
killall Safari

## Finder
# Show path bar
defaults write com.apple.finder "ShowPathbar" -bool "true"
# Keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
# Save to disk location
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false"
# Show status bar
defaults write com.apple.finder "ShowStatusBar" -bool "true"
killall Finder

## Trackpad
# Enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool "true"

## Keyboard
# Repeats the key as long as it is held down
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool "false"
# Fn key usage: Set to: Show Emoji & Symbols
defaults write com.apple.HIToolbox AppleFnUsageType -int "2"
# key repeat rate (default: 5)
defaults write NSGlobalDomain KeyRepeat -int 6
# delay until repeat (default: 30)
defaults write NSGlobalDomain InitialKeyRepeat -int 25
# correct spelling automatically (default: on)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# capitalize words automatically (default: on)
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# show inline predictive text (default: on)
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false
# add period with double-space (default: on)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# use smart quotes and dashes (default: on)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# use dictation (default: set in setup assistant or off)
defaults write com.apple.assistant.support "Dictation Enabled" -bool false
defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool false

## Mission Control
# Group windows by application
defaults write com.apple.dock "expose-group-apps" -bool "true"
killall Dock

## Lock Screen
# turn display off on battery when inactive (default: 2 minutes)
# time in minutes
# never = 0
sudo pmset -b displaysleep 5
# turn display off on power adapter when inactive (default: 10 minutes)
# time in minutes
# never = 0
sudo pmset -c displaysleep 20

