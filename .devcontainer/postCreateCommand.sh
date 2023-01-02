#!/bin/bash

# Stop script on error
set -e

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Update submodules
git submodule update --init

# Set specific Git settings for container
if [[ $(git config --get commit.gpgsign) == true ]]; then
	echo "Disabling gpgsign on Git config in worktree"
	git config --worktree commit.gpgsign false
else
	echo "Git config is not using gpgsign, proceeding..."
fi

# Install the Azure PowerShell module
pwsh -Command 'Install-Module Az -Force -AcceptLicense'

# Unset to revert it from noninteractive
unset DEBIAN_FRONTEND
