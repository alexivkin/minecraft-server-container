#!/bin/bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo Give me the name of the server .env file
    exit 0
fi

CONFIG=$1 #"$NAME.env"
NAME=${CONFIG%%.*}

# sanity checks
if [[ ! -f $CONFIG ]]; then
    echo "Missing configuration file $CONFIG. It's a bash env file settings"
    exit 1
fi

# source all the configs now, including version
. $CONFIG

mkdir -p world-$NAME
echo "$SERVER_PROPS" > world-$NAME/server.properties

# should run with -i so the STDIO remains attached, but without -t so commands can be piped (a pipe is not a TTY)
docker run --name minecraft-server-$NAME -i --env-file $CONFIG -p $PORT:25565 -v $(pwd)/world-$NAME:/data/world --restart unless-stopped alexivkin/minecraft-server:$VER
