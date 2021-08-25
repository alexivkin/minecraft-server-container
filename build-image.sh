#!/bin/bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Specify the Minecraft Mainline Server Version or "latest" for the latest version. If it ends in "-forge" then the forge server will be built"
    exit 0
fi

VERSIONS_JSON="https://launchermeta.mojang.com/mc/game/version_manifest.json"
FORGE_VERSIONS_JSON="http://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json"

VERSION_TAG=$1

if [[ $VERSION_TAG == *-forge ]]; then
    MAINLINE_VERSION=${VERSION_TAG%-forge}
    forge="true"
else
    MAINLINE_VERSION="$VERSION_TAG"
    forge=""
fi

if [[ $MAINLINE_VERSION == "latest" ]]; then
    MAINLINE_VERSION=$(curl -fsSL $VERSIONS_JSON | jq -r '.latest.release')
fi

echo Checking the version ...
# check if the version is valid for the mainline server (prereq for forge as well)
MAINLINE_URL=$(curl -s $VERSIONS_JSON | jq --arg VERSION "$MAINLINE_VERSION" --raw-output '[.versions[]|select(.id == $VERSION)][0].url')
if [[ "$MAINLINE_URL" == "null" ]]; then
   echo No such version $MAINLINE_VERSION for the mainline server.
   exit 1
fi

# check if the forge version for this serevr exists
if [[ $forge ]]; then
    FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-recommended\"]")
    if [ $FORGE_VERSION = null ]; then
        FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-latest\"]")
        if [ $FORGE_VERSION = null ]; then
            FORGE_SUPPORTED_VERSIONS=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r '.promos| keys[] | rtrimstr("-latest") | rtrimstr("-recommended")' | sort -u | tr '\n' ' ')
            echo "Version $MAINLINE_VERSION is not supported by Forge. Supported versions are $FORGE_SUPPORTED_VERSIONS"
            exit 2
        fi
    fi
else
    FORGE_VERSION="noforge"
fi

echo "Preparing the context..."

verfolder=".build-cache/server-$VERSION_TAG"
mkdir -p $verfolder
cd $verfolder

if [[ $forge ]]; then
    ../../download-forge-server.sh $MAINLINE_VERSION
else
    mkdir -p libraries
    ../../download-minecraft-server.sh $MAINLINE_VERSION
fi

cd ../..
cp minecraft-server.sh Dockerfile "$verfolder"

# use dynamic tagging to switch base images
version_slug=$(echo $MAINLINE_VERSION | cut -d . -f 2)
if [[ $version_slug -le 16 ]]; then
    docker pull openjdk:8-jre-alpine
    docker tag openjdk:8-jre-alpine java-base-image
else
    docker pull openjdk:16-alpine
    docker tag openjdk:16-alpine java-base-image
fi

docker build $verfolder -t alexivkin/minecraft-server:$VERSION_TAG --build-arg FORGE_INSTALLER="forge-$MAINLINE_VERSION-$FORGE_VERSION-installer.jar"

if [[ $1 == "latest" ]]; then
    docker tag alexivkin/minecraft-server:$VERSION_TAG latest
fi

#rm -rf $verfolder
echo "done"
