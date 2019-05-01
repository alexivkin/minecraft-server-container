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

# pre-create the folder so docker does not create it as root
mkdir -p $(pwd)/world-$NAME
# should run with -i so the STDIO remains attached, but without -t so commands can be piped (a pipe is not a TTY)
# cant use --env-file $CONFIG - does not support multiline envs

docker run --restart unless-stopped --name minecraft-server-$NAME -di -e MEMORY=$MEMORY -e CPUCOUNT=$CPUCOUNT -e OPS=$OPS -e WHITELIST=$WHITELIST -e SERVERPROPS="$SERVERPROPS" -p $PORT:25565 -v $(pwd)/world-$NAME:/data/world alexivkin/minecraft-server:$VER
