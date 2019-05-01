#/bin/bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo Give me the name of the server .env file, then the command
    exit 0
fi

# run a server commend and show output
# only works if there is one container
#containerid=$(docker ps -aq --filter ancestor=alexivkin/minecraft-server --format="{{.ID}}")

CONFIG=$1 #"$NAME.env"
NAME=${CONFIG%%.*}

time=$(date +%Y-%m-%dT%T.%N)
# assumes there is one java process runnning in the container
#docker exec minecraft-server-$NAME "echo ${@:2} > /proc/$(pgrep -f minecraft_server)/fd/0"
docker exec minecraft-server-$NAME sh -c 'echo "'${@:2}'" > /proc/$(pgrep -f minecraft_server)/fd/0'
docker logs --since "$time" $containerid
