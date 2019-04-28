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

FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-recommended\"]")
if [ $FORGE_VERSION = null ]; then
    FORGE_VERSION=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r ".promos[\"$MAINLINE_VERSION-latest\"]")
    if [ $FORGE_VERSION = null ]; then
        FORGE_SUPPORTED_VERSIONS=$(curl -fsSL $FORGE_VERSIONS_JSON | jq -r '.promos| keys[] | rtrimstr("-latest") | rtrimstr("-recommended")' | sort -u | tr '\n' ' ')
        echo "Version $MAINLINE_VERSION is not supported by Forge. Supported versions are $FORGE_SUPPORTED_VERSIONS"
        exit 2
    fi
fi

# download the mainline server
SERVER="minecraft_server.$MAINLINE_VERSION.jar"
echo -n "Downloading minecraft server $MAINLINE_VERSION ..."
curl -sSL -o $SERVER $(curl -s $(curl -s $MAINLINE_VERSIONS_JSON | \
    jq --arg VERSION "$MAINLINE_VERSION" --raw-output '[.versions[]|select(.id == $VERSION)][0].url') | jq --raw-output '.downloads.server.url')


normForgeVersion=$MAINLINE_VERSION-$FORGE_VERSION-$norm
shortForgeVersion=$MAINLINE_VERSION-$FORGE_VERSION

FORGE_INSTALLER="forge-$shortForgeVersion-installer.jar"

if [[ ! -f $FORGE_INSTALLER ]]; then
    echo "Downloading $normForgeVersion installer"
    downloadUrl=http://files.minecraftforge.net/maven/net/minecraftforge/forge/$shortForgeVersion/forge-$shortForgeVersion-installer.jar
    echo "$downloadUrl"
    if ! curl -o $FORGE_INSTALLER -fsSL $downloadUrl; then
        downloadUrl=http://files.minecraftforge.net/maven/net/minecraftforge/forge/$normForgeVersion/forge-$normForgeVersion-installer.jar
        echo "...trying $downloadUrl"
        if ! curl -o $FORGE_INSTALLER -fsSL $downloadUrl; then
            echo no url worked
            exit 3
        fi
    fi
fi

if [[ ! -f "forge-$shortForgeVersion-universal.jar" ]]; then
    echo "Extracting the forge server $shortForgeVersion"
    jar xvf $FORGE_INSTALLER forge-$shortForgeVersion-universal.jar
fi

echo "Getting the libs for $shortForgeVersion ..."

libdir="libraries"

#rooturl="http://files.minecraftforge.net/maven" # from http://files.minecraftforge.net/mirror-brand.list

# stuff into a var for later use
profile=$(unzip -qc $FORGE_INSTALLER install_profile.json)

# get all the necessary libs for this forge server
for name in $(echo $profile | jq -r '.versionInfo.libraries[] | select(.serverreq) | .name'); do
    # split the name up
    s=(${name//:/ })
    # and rebuild it
    class=${s[0]}
    lib=${s[1]}
    ver=${s[2]}
    file="$lib-$ver.jar"
    path="${class//./\/}/$lib/$ver"
    baseurl=$(echo $profile | jq -r '.versionInfo.libraries[] | select(.name=="'$name'") | .url')
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
