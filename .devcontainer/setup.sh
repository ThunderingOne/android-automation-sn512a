#!/bin/bash
echo "Setting up Android Automation Environment..."
sudo apt-get update
sudo apt-get install -y android-tools-adb android-tools-fastboot wget curl git python3-pip
pip install --upgrade pip pyusb pyserial
cd /tmp && git clone https://github.com/bkerler/mtkclient.git && cd mtkclient && pip install -r requirements.txt
mkdir -p ~/android-automation/{workspace,logs,scripts}
echo "Setup complete!"
