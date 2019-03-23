#!/bin/bash

set -e

# install https://github.com/tj/n
sh -c "npm install -g n"
sh -c "n -V"

# For test only
if [ -n "$REGISTRY_AUTH_TOKEN" ]; then
  echo "ADDING TOKEN"
  echo "//${REGISTRY_URL}/:_authToken=${REGISTRY_AUTH_TOKEN}" > .npmrc
  sh -c "npm whoami --registry https://${REGISTRY_URL}"
fi

sh -c "$*"
