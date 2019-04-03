#!/usr/bin/env bash

# Quit on error and if unset variables are referenced
set -eu

# Fail if a command fails inside a pipe
set -o pipefail

if [ $# -eq 0 ]; then
    echo "Expected user and server as a parameter (e.g. 'username server_to_point_to')"
    exit 1
fi

# The server to deploy to
USER=$1
SERVER=$2
# The path to the static folder
SERVER_FOLDER=/var/www/htdocs

npm run build

# Remove the directories then insert later
ssh $USER@$SERVER rm -rfv $SERVER_FOLDER/*

# Client
scp -r ./dist/* $USER@$SERVER:$SERVER_FOLDER

ssh $USER@$SERVER "cd $SERVER_FOLDER && npm install --production"
ssh $USER@$SERVER "chmod 775 -R $SERVER_FOLDER/*"
