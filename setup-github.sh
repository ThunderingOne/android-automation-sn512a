#!/bin/bash
# GitHub Setup Script
# Author: Terrell Russell
# Purpose: Configure GitHub access via SSH or token

echo "=========================================="
echo "GitHub Setup Script"
echo "=========================================="

# Check if SSH key is added to GitHub
echo "Testing SSH connection to GitHub..."
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
if [ $? -eq 0 ]; then
    echo "✅ SSH authentication successful"
    USE_SSH=true
else
    echo "⚠️ SSH key not added to GitHub yet"
    echo "Please add the public key to: https://github.com/settings/keys"
    USE_SSH=false
fi

# Check for GitHub token
if [ -n "$GH_TOKEN" ]; then
    echo "✅ GitHub token found"
    USE_TOKEN=true
else
    echo "⚠️ No GitHub token found"
    echo "You can:"
    echo "1. Add SSH key to GitHub (recommended)"
    echo "2. Create token at: https://github.com/settings/tokens"
    echo "3. Set token: export GH_TOKEN=your_token_here"
    USE_TOKEN=false
fi

# Configure git to use SSH if available
if [ "$USE_SSH" = true ]; then
    echo "Configuring git to use SSH..."
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo "✅ Git configured for SSH"
elif [ "$USE_TOKEN" = true ]; then
    echo "Configuring git to use token..."
    git config --global url."https://oauth2:$GH_TOKEN@github.com/".insteadOf "https://github.com/"
    echo "✅ Git configured for token"
else
    echo "⚠️ No authentication method configured"
    echo "Please add SSH key or set GH_TOKEN"
fi

# Create repository if it doesn't exist
REPO_NAME="android-automation-sn512a"
echo ""
echo "Creating repository: $REPO_NAME"

if [ "$USE_SSH" = true ] || [ "$USE_TOKEN" = true ]; then
    gh repo create "$REPO_NAME" --public --description "Android automation framework for SN512A device" 2>&1 || echo "Repository may already exist"
    echo "✅ Repository setup complete"
    echo "URL: https://github.com/TerrellRussell/$REPO_NAME"
else
    echo "⚠️ Cannot create repository without authentication"
fi

echo ""
echo "=========================================="
echo "GitHub Setup Complete"
echo "=========================================="
