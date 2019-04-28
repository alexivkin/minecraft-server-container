#/bin/bash

# run a server commend and show output
# only works if there is one container
containerid=$(docker ps -aq --filter ancestor=alexivkin/minecraft-server --format="{{.ID}}")

time=$(date +%Y-%m-%dT%T.%N)
# assumes there is one java process runnning in the container
docker exec $containerid echo "$@" > /proc/$(pgrep -f server.jar)/fd/0
docker logs --since "$time" $containerid
