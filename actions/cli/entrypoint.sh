#!/bin/bash

set -e

# install https://github.com/tj/n
sh -c "npm install -g n"
sh -c "n -V"

# adding git config
sh -c "git config --global user.email \"melody@trivago.com\""
sh -c "git config --global user.name \"melody\""

# For test only
if [ -n "$REGISTRY_AUTH_TOKEN" ]; then
  echo "ADDING TOKEN"
  echo "//${REGISTRY_URL}/:_authToken=${REGISTRY_AUTH_TOKEN}" > .npmrc
  sh -c "npm whoami --registry https://${REGISTRY_URL}"
fi

sh -c "$*"
