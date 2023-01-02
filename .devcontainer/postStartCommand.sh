#!/bin/bash

# Stop script on error
set -e

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

#
# Execution
#

# Get the latest subscriptions
az account list --refresh

# Update the submodules
git pull
git submodule update --remote

# Unset to revert it from noninteractive
unset DEBIAN_FRONTEND
