#!/bin/bash

set -euo pipefail

# get the latest version and build the latest
if [[ $# -eq 0 ]]; then
    echo Specify the version or "latest"
    exit 0
fi

VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json

if [[ $1 == "latest" ]]; then
    VERSION=$(curl -fsSL $VERSIONS_JSON | jq -r '.latest.release')
else
    VERSION=$1
fi

SERVER="minecraft_server.$VERSION.jar"

if [[ -f $SERVER ]]; then
    echo "Minecraft server $VERSION already downloaded"
else
    echo -n "Downloading minecraft server $VERSION ..."
    # triplecurl for the win!
    curl -sSL -o $SERVER $(curl -s $(curl -s $VERSIONS_JSON | \
        jq --arg VERSION "$VERSION" --raw-output '[.versions[]|select(.id == $VERSION)][0].url') | jq --raw-output '.downloads.server.url')
    echo "done"
fi
