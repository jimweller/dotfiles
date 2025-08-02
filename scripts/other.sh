#!/bin/bash

if [ "$(uname)" != "Linux" ]; then
  echo "Not Linux. Exiting."
  exit 0
fi


# install yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O $HOME/bin/yq &&\
sudo chmod +x $HOME/bin/yq