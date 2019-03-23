#!/bin/bash

set -e
if ! git diff-files --quiet --
then
    echo >&2 "cannot $1: you have unstaged changes."
    git diff-files --name-status -r --ignore-submodules -- >&2
    exit 1
fi
if ! git diff-index --cached --quiet HEAD --
then
    echo >&2 "cannot $1: your index contains uncommitted changes."
    git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
    exit 1
fi

echo
# Peer dependency prompt
read -p "IS THIS A MAJOR UPDATE? (e.g. 1.0.0 => 2.0.0)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    read -p "DID YOU UPDATE AND COMMIT PEER DEPENDENCIES? 'yarn update-peers'" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Push the recently created tag to github and create release."

    else
        echo "PLEASE RUN 'yarn update-peers' AND COMMIT YOUR CHANGES BEFORE PROCEEDING"
        exit 1
    fi

else
    echo "Push the recently created tag to github and create release."
fi
