#!/bin/bash

# get the latest version and build the latest
#set -x
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo Specify the Minecraft Server Version or "latest" for the latest version of the minecraft server to get the compatible neoforge
    exit 0
fi

MAINLINE_VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json
NEOFORGE_VERSIONS_JSON=https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge

if [[ $1 == "latest" ]]; then
    MAINLINE_VERSION=$(curl -fsSL $MAINLINE_VERSIONS_JSON | jq -r '.latest.release')
else
    MAINLINE_VERSION=$1
fi

NEOFORGE_VERSION=$(curl -fsSL $NEOFORGE_VERSIONS_JSON | jq -r '.versions[]' | { grep "${MAINLINE_VERSION:2}" || true; } | sort --version-sort | tail -1)
if [[ -z $NEOFORGE_VERSION ]]; then
    NEOFORGE_SUPPORTED_VERSIONS=$(curl -fsSL $NEOFORGE_VERSIONS_JSON | jq -r '.versions[]' | sed -r 's/([0-9]+\.[0-9]+).*/\1/;s/^/1./' | sort -Vu | sed -z 's/\n/, /g')
    echo -e "ERROR: Version $MAINLINE_VERSION is not supported by NeoForge. Supported versions are:\n$NEOFORGE_SUPPORTED_VERSIONS"
    exit 2
fi

echo "Downloading NeoForge version $1..."

NEOFORGE_INSTALLER="neoforge-$MAINLINE_VERSION-$NEOFORGE_VERSION-installer.jar"
if [[ ! -f $NEOFORGE_INSTALLER ]]; then
    echo "Downloading $NEOFORGE_VERSION installer"
    downloadUrl=https://maven.neoforged.net/releases/net/neoforged/neoforge/$NEOFORGE_VERSION/neoforge-$NEOFORGE_VERSION-installer.jar
    #echo "$downloadUrl"
    if ! curl -o $NEOFORGE_INSTALLER -fsSL $downloadUrl; then
        echo "Can't download $downloadUrl"
        exit 3
    fi
else
	echo "NeoForge installer $NEOFORGE_INSTALLER is already downloaded"
fi

mkdir -p libraries # for compatibility with the generic dockerfile
