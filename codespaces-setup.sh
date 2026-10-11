#!/bin/bash
# GitHub Codespaces Setup Script
# Author: Terrell Russell
# Purpose: Set up GitHub Codespaces for Android automation

LOG_DIR="./codespaces-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$LOG_DIR"

echo "=========================================="
echo "GitHub Codespaces Setup"
echo "Started: $(date)"
echo "=========================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not installed. Installing..."
    # For Windows, recommend manual installation
    echo "Please install GitHub CLI from: https://cli.github.com/"
    echo "After installation, run this script again."
    exit 1
fi

# Check if user is authenticated
echo "Checking GitHub authentication..."
gh auth status &> "$LOG_DIR/gh_auth_$TIMESTAMP.txt"
if [ $? -ne 0 ]; then
    echo "Not authenticated with GitHub. Please run: gh auth login"
    echo "Follow the prompts to authenticate with GitHub."
    exit 1
fi

echo "GitHub authenticated successfully"

# Create GitHub repository for automation
echo "Creating GitHub repository..."
REPO_NAME="android-automation-sn512a"
gh repo create "$REPO_NAME" --public --description "Android automation framework for SN512A device" &> "$LOG_DIR/repo_create_$TIMESTAMP.txt"

if [ $? -eq 0 ]; then
    echo "Repository created: https://github.com/TerrellRussell/$REPO_NAME"
else
    echo "Repository may already exist or creation failed"
    cat "$LOG_DIR/repo_create_$TIMESTAMP.txt"
fi

# Initialize git repository locally
echo "Initializing git repository..."
cd /c/Users/Terrell/android-automation
git init &> "$LOG_DIR/git_init_$TIMESTAMP.txt"
git remote add origin "https://github.com/TerrellRussell/$REPO_NAME.git" &> "$LOG_DIR/git_remote_$TIMESTAMP.txt"

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Logs
*.log
*-logs/
accessibility-analysis/
monitoring-logs/
setup-logs/
unlock-logs/
automation-logs/
codespaces-logs/
*.txt

# Temporary files
*.tmp
*.bak
*.swp
*~

# OS files
.DS_Store
Thumbs.db
desktop.ini

# IDE files
.vscode/
.idea/
*.iml
GITIGNORE

# Create GitHub Codespaces configuration
mkdir -p .devcontainer
cat > .devcontainer/devcontainer.json << 'DEVCONTAINER'
{
    "name": "Android Automation Environment",
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainers/features/python:1": {
            "version": "3.11"
        },
        "ghcr.io/devcontainers/features/git:1": {}
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-vscode.vscode-json",
                "redhat.vscode-yaml",
                "ms-azuretools.vscode-docker",
                "GitHub.vscode-pull-request-github"
            ]
        }
    },
    "forwardPorts": [5555],
    "postCreateCommand": "bash .devcontainer/setup.sh",
    "remoteUser": "vscode"
}
DEVCONTAINER

cat > .devcontainer/setup.sh << 'SETUP'
#!/bin/bash
# Setup script for GitHub Codespaces

echo "Setting up Android Automation Environment in Codespaces..."

# Install ADB
echo "Installing ADB..."
sudo apt-get update
sudo apt-get install -y android-tools-adb android-tools-fastboot

# Install Python dependencies for MTKClient
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install pyusb pyserial

# Install MTKClient dependencies
echo "Installing MTKClient..."
cd /tmp
git clone https://github.com/bkerler/mtkclient.git
cd mtkclient
pip install -r requirements.txt

# Install additional tools
echo "Installing additional tools..."
sudo apt-get install -y wget curl git python3-pip

# Set up Android SDK (minimal)
echo "Setting up Android SDK..."
mkdir -p ~/android-sdk
cd ~/android-sdk
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
export PATH=$PATH:~/android-sdk/platform-tools

# Create workspace directories
echo "Creating workspace directories..."
mkdir -p ~/android-automation/workspace
mkdir -p ~/android-automation/logs
mkdir -p ~/android-automation/scripts

# Copy automation scripts
echo "Copying automation scripts..."
cp -r /workspaces/android-automation-sn512a/*.sh ~/android-automation/scripts/
chmod +x ~/android-automation/scripts/*.sh

echo "Setup complete!"
echo "Environment ready for Android automation"
SETUP

chmod +x .devcontainer/setup.sh

# Create GitHub Actions workflow
mkdir -p .github/workflows
cat > .github/workflows/android-automation.yml << 'WORKFLOW'
name: Android Automation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  analyze:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install ADB
      run: |
        sudo apt-get update
        sudo apt-get install -y android-tools-adb android-tools-fastboot
    
    - name: Install MTKClient dependencies
      run: |
        pip install pyusb pyserial
    
    - name: Run accessibility analysis
      run: |
        chmod +x ./accessibility-analysis.sh
        ./accessibility-analysis.sh || true
    
    - name: Run third-party monitoring
      run: |
        chmod +x ./third-party-monitor.sh
        ./third-party-monitor.sh || true
    
    - name: Upload logs
      uses: actions/upload-artifact@v3
      with:
        name: automation-logs
        path: |
          accessibility-analysis/
          monitoring-logs/
          setup-logs/
          unlock-logs/
          automation-logs/
WORKFLOW

# Create codespace configuration
cat > .codespacesrc << 'CODESPACES'
# GitHub Codespaces Configuration
# Author: Terrell Russell

# Machine type
CODESPACE_MACHINE=standardLinux32gb

# Timeout
CODESPACE_TIMEOUT=30m

# Auto-start
CODESPACE_AUTO_START=true

# Dotfiles
CODESPACE_DOTFILES_REPO=https://github.com/TerrellRussell/dotfiles

# Environment variables
export ANDROID_SDK_HOME=~/android-sdk
export PATH=$PATH:~/android-sdk/platform-tools
export MTKCLIENT_PATH=/tmp/mtkclient
CODESPACES

# Create start script for Codespaces
cat > start-codespace.sh << 'STARTSCRIPT'
#!/bin/bash
# Start GitHub Codespace for Android Automation

echo "Starting GitHub Codespace..."

# Check authentication
gh auth status
if [ $? -ne 0 ]; then
    echo "Not authenticated. Run: gh auth login"
    exit 1
fi

# Create codespace
echo "Creating codespace..."
gh codespace create --repo TerrellRussell/android-automation-sn512a --machine standardLinux32gb --idle-timeout 30m

# Wait for codespace to start
echo "Waiting for codespace to start..."
sleep 30

# Connect to codespace
echo "Connecting to codespace..."
gh codespace ssh

echo "Codespace started. Connect via: gh codespace ssh"
echo "Or open in browser: https://github.com/codespaces"
STARTSCRIPT

chmod +x start-codespace.sh

# Commit and push to GitHub
echo "Committing and pushing to GitHub..."
git add . &> "$LOG_DIR/git_add_$TIMESTAMP.txt"
git commit -m "Android automation framework for SN512A" &> "$LOG_DIR/git_commit_$TIMESTAMP.txt"
git push -u origin main &> "$LOG_DIR/git_push_$TIMESTAMP.txt"

if [ $? -eq 0 ]; then
    echo "Successfully pushed to GitHub"
    echo "Repository: https://github.com/TerrellRussell/$REPO_NAME"
    echo "Codespace: https://github.com/codespaces"
else
    echo "Push failed. Check logs in $LOG_DIR"
fi

echo ""
echo "=========================================="
echo "GitHub Codespaces Setup Complete"
echo "Finished: $(date)"
echo "=========================================="
echo "Repository: https://github.com/TerrellRussell/$REPO_NAME"
echo "Codespace: https://github.com/codespaces"
echo "To start codespace: ./start-codespace.sh"
