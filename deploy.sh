#!/bin/bash

# ----------------------
# Meteor Azure
# Version: 1.4.5
# ----------------------

# ----------------------
# KUDU Deployment Script
# Version: 1.0.8
# ----------------------

# Environment
# ------

SCRIPT_DIR="${BASH_SOURCE[0]%\\*}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
ARTIFACTS=$SCRIPT_DIR/../artifacts

if [[ ! -n "$DEPLOYMENT_SOURCE" ]]; then
  DEPLOYMENT_SOURCE=$SCRIPT_DIR
fi

if [[ ! -n "$DEPLOYMENT_TARGET" ]]; then
  DEPLOYMENT_TARGET=$ARTIFACTS/wwwroot
else
  KUDU_SERVICE=true
fi

# Prepare cache directory
if [ ! -d D:/home/meteor-azure ]; then
  mkdir D:/home/meteor-azure
fi

# Setup
# ------------

cd D:/home/meteor-azure;

# Install NVM
if [ ! -d nvm ]; then
  echo meteor-azure: Installing NVM
  curl -L -o nvm-noinstall.zip "https://github.com/coreybutler/nvm-windows/releases/download/1.1.1/nvm-noinstall.zip"
  unzip nvm-noinstall.zip -d nvm
  rm nvm-noinstall.zip
  (echo root: D:/home/meteor-azure/nvm && echo proxy: none) > nvm/settings.txt
fi

# Install custom Node
echo meteor-azure: Setting Node version
export NVM_HOME=D:/home/meteor-azure/nvm
nvm/nvm.exe install $METEOR_AZURE_NODE_VERSION 32
if [ ! -e "nvm/v$METEOR_AZURE_NODE_VERSION/node.exe" ]; then
  cp "nvm/v$METEOR_AZURE_NODE_VERSION/node32.exe" "nvm/v$METEOR_AZURE_NODE_VERSION/node.exe"
fi
export PATH="$HOME/meteor-azure/nvm/v$METEOR_AZURE_NODE_VERSION:$PATH"
echo "meteor-azure: Now using Node $(node -v) (32-bit)"

# Install custom NPM
echo meteor-azure: Setting NPM version
if [ "$(npm -v)" != "$METEOR_AZURE_NPM_VERSION" ]; then
  cmd //c npm install -g "npm@$METEOR_AZURE_NPM_VERSION"
fi
echo "meteor-azure: Now using NPM v$(npm -v)"

# Install JSON tool
if ! hash json 2>/dev/null; then
  echo meteor-azure: Installing JSON tool
  npm install -g json
fi

# Validate setup
if [ "$(node -v)" != "v$METEOR_AZURE_NODE_VERSION" ]; then
  echo "ERROR! Could not install Node"
  exit 1
fi
if [ "$(npm -v)" != "$METEOR_AZURE_NPM_VERSION" ]; then
  echo "ERROR! Could not install NPM"
  exit 1
fi
if ! hash json 2>/dev/null; then
  echo "ERROR! Could not install JSON tool"
  exit 1
fi

# Compilation
# ------------

cd D:/home/bundle
echo meteor-azure: COMPILE
cp "$DEPLOYMENT_SOURCE\web.config" web.config
(echo nodeProcessCommandLine: "D:\home\meteor-azure\nvm\v$METEOR_AZURE_NODE_VERSION\node.exe") > iisnode.yml
json -I -f programs/server/package.json -e "this.main='../../main.js';this.scripts={ start: 'node ../../main' }"


# Deployment
# ----------

# Sync bundle
echo meteor-azure: Deploying bundle
robocopy D:/home/bundle $DEPLOYMENT_TARGET //mt //mir //nfl //ndl //njh //njs //nc //ns //np > /dev/null

# Install Meteor server
echo meteor-azure: Installing Meteor server
cd "$DEPLOYMENT_TARGET\programs\server"
npm install --production

echo meteor-azure: Finished successfully
