#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
  echo "Not MacOS. Exiting."
  exit 1
fi

echo "Updating Homebrew packages..."