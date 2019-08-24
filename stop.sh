#/bin/bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo Give me the name of the server .env file. Use -f to stop without warning
    exit 0
fi

if [[ $# -eq 2 && $2 == "-f" ]]; then
    force="true"
else
    force="false"
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

if [[ $force == "false" ]]; then
    ./cmd.sh $CONFIG say "SERVER SHUTTING DOWN IN 10 SECONDS. Saving map..."
    ./cmd.sh $CONFIG save-all
    sleep 10
    ./cmd.sh $CONFIG stop
    sleep 2
fi

# stop with the docker command so it does not autorestart
docker stop minecraft-server-$NAME
docker rm minecraft-server-$NAME
