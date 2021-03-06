#!/bin/bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Give me the name of the server .env file. Use -f option to run in the foreground mode"
    exit 0
fi
# choose interactive (foreground) or server (background) docker options
if [[ $# -eq 2 && $2 == "-f" ]]; then
    runopt="-it --rm"
else
    runopt="-d --restart unless-stopped -i"
fi

# Check if the container is already running, then stop/remove it
check_and_stop() {
    container=$1
    #echo Checking for $container
    if [ "$(docker ps -aq -f name="$container\$")" ]; then
        if [ "$(docker ps -aq -f status=exited -f name="$container\$")" ]; then # if [ $(docker inspect -f '{{.State.Running}}' backend) = "true" ]; then
            echo "Removing $container"
            docker rm $container
        else
            # handle running and restarting containers
            echo "Stopping and removing $container"
            docker stop $container
            docker rm $container
        fi
    fi
}

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
mkdir -p $(pwd)/world-$NAME-extras

# should run with -i so the STDIO remains attached, but without -t so commands can be piped (a pipe is not a TTY)
# cant use --env-file $CONFIG - does not support multiline envs
# debug

check_and_stop minecraft-server-$NAME

docker run $runopt --name minecraft-server-$NAME -e MEMORY=$MEMORY -e CPUCOUNT=$CPUCOUNT -e OPS=$OPS -e WHITELIST=$WHITELIST -e SERVERPROPS="$SERVERPROPS" -p $PORT:25565 -v $(pwd)/world-$NAME:/data/world -v $(pwd)/world-$NAME-extras:/extras alexivkin/minecraft-server:$VER
#echo ">>> Tailing logs..."
#docker logs -f minecraft-server-$NAME
