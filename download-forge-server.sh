#!/bin/bash

# get the latest version and build the latest

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo Specify the Minecraft Server Version or "latest" for the latest version of the minecraft server to get the compatible forge for
    exit 0
fi

MAINLINE_VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json
FORGE_VERSIONS_JSON=http://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json

if [[ $1 == "latest" ]]; then
    MAINLINE_VERSION=$(curl -fsSL $MAINLINE_VERSIONS_JSON | jq -r '.latest.release')
else
    MAINLINE_VERSION=$1
fi

norm=$MAINLINE_VERSION

case $MAINLINE_VERSION in
    *.*.*)
      norm=$MAINLINE_VERSION ;;
    *.*)
      norm=${MAINLINE_VERSION}.0 ;;
esac

#FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-recommended\"]")
#if [ $FORGE_VERSION = null ]; then
    FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-latest\"]")
    if [ $FORGE_VERSION = null ]; then
        FORGE_SUPPORTED_VERSIONS=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r '.promos| keys[] | rtrimstr("-latest") | rtrimstr("-recommended")' | sort -u | tr '\n' ' ')
        echo "Version $MAINLINE_VERSION is not supported by Forge. Supported versions are $FORGE_SUPPORTED_VERSIONS"
        exit 2
    fi

#fi

# temp bugfix
if [[ $FORGE_VERSION == "27.0.24" ]]; then
    FORGE_VERSION="27.0.21"
fi

normForgeVersion=$MAINLINE_VERSION-$FORGE_VERSION-$norm
shortForgeVersion=$MAINLINE_VERSION-$FORGE_VERSION

FORGE_INSTALLER="forge-$shortForgeVersion-installer.jar"

if [[ ! -f $FORGE_INSTALLER ]]; then
    echo "Downloading the forge $normForgeVersion installer: $FORGE_INSTALLER"
    downloadUrl=http://files.minecraftforge.net/maven/net/minecraftforge/forge/$shortForgeVersion/forge-$shortForgeVersion-installer.jar
    #echo "$downloadUrl"
    if ! curl -o $FORGE_INSTALLER -fsSL $downloadUrl; then
        downloadUrl=http://files.minecraftforge.net/maven/net/minecraftforge/forge/$normForgeVersion/forge-$normForgeVersion-installer.jar
        echo "...trying $downloadUrl"
        if ! curl -o $FORGE_INSTALLER -fsSL $downloadUrl; then
            echo no url worked
            exit 3
        fi
    fi
else
    echo "Forge installer $FORGE_INSTALLER is already downloaded"
fi

# for versions 27 and onward (minecraft 1.14) download the installer and run it during the Docker build
if [[ ${FORGE_VERSION%%.*} -ge 27 ]]; then
#if [[ $MAINLINE_VERSION =~ 1\.[1-9][4-9].* ]]; then
    #export RUN_INSTALLER="true" # pass the flag to the
    mkdir -p libraries # for compatibility with the generic dockerfile
    exit 0
fi

# for older versions do a manuall install below:

# download the mainline server
SERVER="minecraft_server.$MAINLINE_VERSION.jar"
if [[ ! -f $SERVER ]]; then
    echo "Downloading minecraft server $MAINLINE_VERSION ..."
    curl -sSL -o $SERVER $(curl -s $(curl -s $MAINLINE_VERSIONS_JSON | \
        jq --arg VERSION "$MAINLINE_VERSION" --raw-output '[.versions[]|select(.id == $VERSION)][0].url') | jq --raw-output '.downloads.server.url')
else
    echo "Minecraft server $SERVER is already downloaded"
fi

FORGE_SERVER="forge-$shortForgeVersion-universal.jar"

if [[ ! -f $FORGE_SERVER ]]; then
    echo "Extracting the forge server $shortForgeVersion"
    unzip -qj $FORGE_INSTALLER maven/net/minecraftforge/forge/$shortForgeVersion/$FORGE_SERVER || true
    if [[ ! -f $FORGE_SERVER ]]; then
        # for older than 1.14 forge installers
        unzip -qj $FORGE_INSTALLER $FORGE_SERVER
        if [[ ! -f $FORGE_SERVER ]]; then
           echo "Something went wrong extracting $FORGE_SERVER from $FORGE_INSTALLER"
           exit 1
        fi
        echo "Extracted from the root folder"
    fi
else
    echo "Forge server $FORGE_SERVER is already extracted"
fi

echo "Getting the libs for $shortForgeVersion ..."

libdir="libraries"

#rooturl="http://files.minecraftforge.net/maven" # from http://files.minecraftforge.net/mirror-brand.list

# stuff into a var for later use
profile=$(unzip -qc $FORGE_INSTALLER install_profile.json)
# check the installer
#if [[ $(echo "$profile" | jq -r '.versionInfo') == 'null' ]]; then
    # newer installer, we will run it at the
names=$(echo "$profile" | jq -r '.versionInfo.libraries[] | select(.serverreq) | .name')
# get all the necessary libs for this forge server
for name in $names; do
    # split the name up
    s=(${name//:/ })
    # and rebuild it
    class=${s[0]}
    lib=${s[1]}
    ver=${s[2]}
    file="$lib-$ver.jar"
    path="${class//./\/}/$lib/$ver"
    baseurl=$(echo "$profile" | jq -r '.versionInfo.libraries[] | select(.name=="'$name'") | .url')
    if [[ $baseurl == "null" ]]; then
        baseurl="https://libraries.minecraft.net"
    fi
    mkdir -p "$libdir/$path"
    dest="$libdir/$path/$file"
    if [[ ! -f $dest ]]; then
        echo "$baseurl/$path/$file"
        if ! curl -fsSL -o $dest "$baseurl/$path/$file"; then
            # get and unpack augmented pack200 file
            echo "...trying $baseurl/$path/$file.pack.xz"
            if ! curl -fsSL -o $dest.pack.xz "$baseurl/$path/$file.pack.xz"; then
                echo "cant download"
                exit 1
            fi
            xz -d $dest.pack.xz
            hexsiglen=$(xxd -s -8 -l 4 -e $dest.pack | cut -d ' ' -f 2)
            siglen=$(( 16#$hexsiglen ))
            fulllen=$(stat -c %s $dest.pack)
            croplen=$(( $fulllen-$siglen-8 ))
            dd if=$dest.pack of=$dest.pack.crop bs=$croplen count=1 2>/dev/null
            unpack200 $dest.pack.crop $dest
            rm $dest.pack.crop
            rm $dest.pack
        fi
    fi
done

rm $FORGE_INSTALLER
