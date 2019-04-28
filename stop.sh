#/bin/bash

./cmd.sh "say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map..."
./cmd.sh "save-all"
sleep 10

./cmd.sh "stop"
sleep 2

# stop with the docker command so it does not autorestart
docker stop minecraft-server
