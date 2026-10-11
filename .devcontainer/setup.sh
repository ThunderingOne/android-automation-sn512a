#!/bin/bash
set -e
echo "=== Android Automation Environment Setup ==="

sudo apt-get update
sudo apt-get install -y android-tools-adb android-tools-fastboot wget curl git python3-pip unzip libfuse2 fuse

pip install --upgrade pip
pip install pyusb pyserial pycryptodome

WS=/workspaces/android-automation-sn512a
mkdir -p "$WS/tools"
cd "$WS/tools"

[ -d mtkclient ] || git clone https://github.com/bkerler/mtkclient.git
cd mtkclient
git remote add davdiv https://github.com/davdiv/mtkclient.git 2>/dev/null || true
git fetch davdiv plstage
git checkout plstage 2>/dev/null || git checkout -b plstage davdiv/plstage
pip install -r requirements.txt || true
cd "$WS/tools"

[ -d BraX3-repair-tools ] || git clone https://github.com/davdiv/BraX3-repair-tools.git
[ -d Android_boot_image_editor ] || git clone https://github.com/cfig/Android_boot_image_editor.git

echo "=== Setup complete ==="
