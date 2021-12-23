#!/bin/sh

set -o pipefail

if ! touch /data/world/.verify_access; then
  echo "ERROR: /data/world/ doesn't seem to be writable. Please make sure attached directory is writable by uid=$(id -u)"
  exit 2
fi
rm /data/world/.verify_access

if [[ -z "$MEMORY" || -z "$CPUCOUNT" ]]; then # quotes needed here cause of the -z and the || on the alpine sh
    echo "Please specify $MEMORY and $CPUCOUNT parameters"
    exit
fi

trap 'server_shutdown' SIGTERM

function server_shutdown() {
    echo "Stopping the Minecraft server..."
    pid=$(pidof java)
    if [ -z "$pid" ]; then echo "Already stopped"; exit 1; fi
    echo "save-all" > /proc/$pid/fd/0
    echo "stop" > /proc/$pid/fd/0
    # Wait for it to finish saving and exit
    while [ -e /proc/$pid ]; do
        sleep 1
    done
    echo "done"
    exit 0
}

if [[ $OPS ]]; then #-a ! -e ops.txt.converted ]; then
  echo "Setting operators to $OPS"
  echo $OPS | awk -v RS=, '{print}' >> /data/ops.txt
fi

if [[ $WHITELIST ]]; then # -a ! -e white-list.txt.converted ]; then
  echo "Setting user whitelist to $WHITELIST"
  echo $WHITELIST | awk -v RS=, '{print}' >> /data/white-list.txt
fi

if [[ "$SERVERPROPS" ]]; then
  echo "Setting server.properties"
  echo "$SERVERPROPS" >> /data/server.properties
fi

if ls /extras/* 1> /dev/null 2>&1; then
  echo "Copying extras to /data/"
  cp -a /extras/* /data/
fi

# creating a named pipe, so java does not close stdin when moved to the background
mkfifo /data/in
# block the pipe, so it's open forever. Using days instead of `infinity` because old musl from 8-jre-alpine doesn't support it
sleep 100000d > /data/in &
# start forge if one exists
if [[ -f forge*.jar ]]; then
    java -Xmx${MEMORY} -Xms${MEMORY} -XX:+UseG1GC -XX:MaxGCPauseMillis=25 -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPUCOUNT -XX:+AggressiveOpts -jar forge*.jar nogui < /data/in &
else
    # move to background so we can monitor for SIGTERM in this shell
    #java -Xmx${MEMORY} -Xms${MEMORY} -XX:+UseG1GC -XX:MaxGCPauseMillis=25 -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPUCOUNT -XX:+AggressiveOpts -jar minecraft_server*.jar nogui
    java -Xmx${MEMORY} -Xms${MEMORY} -XX:ParallelGCThreads=$CPUCOUNT -jar minecraft_server*.jar nogui < /data/in &
fi
# watch java, exit if stopped/crashed to trigger the container restart
pid=$(pidof java)
if [ -z "$pid" ]; then echo "Minecraft server did not start!"; exit 1; fi
wait $pid
