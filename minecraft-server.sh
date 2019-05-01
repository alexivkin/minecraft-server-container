#!/bin/sh

if ! touch /data/world/.verify_access; then
  echo "ERROR: /data/world/ doesn't seem to be writable. Please make sure attached directory is writable by uid=$(id -u)"
  exit 2
fi
rm /data/world/.verify_access

if [[ -z "$MEMORY" || -z "$CPUCOUNT" ]]; then # quotes needed here cause of the -z and the || on the alpine sh
    echo Please specify \$MEMORY and \$CPUCOUNT parameters
    exit
fi

if [[ $OPS ]]; then #-a ! -e ops.txt.converted ]; then
  echo "Setting ops"
  echo $OPS | awk -v RS=, '{print}' >> /data/ops.txt
fi

if [[ $WHITELIST ]]; then # -a ! -e white-list.txt.converted ]; then
  echo "Setting whitelist"
  echo $WHITELIST | awk -v RS=, '{print}' >> /data/white-list.txt
fi

if [[ "$SERVERPROPS" ]]; then
  echo "Setting server.properties"
  echo "$SERVERPROPS" >> /data/server.properties
fi

# start forge if one exists
if [[ -f forge*.jar ]]; then
    java -Xmx${MEMORY} -Xms${MEMORY} -XX:+UseG1GC -XX:MaxGCPauseMillis=25 -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPUCOUNT -XX:+AggressiveOpts -jar forge*.jar nogui
else
    java -Xmx${MEMORY} -Xms${MEMORY} -XX:+UseG1GC -XX:MaxGCPauseMillis=25 -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPUCOUNT -XX:+AggressiveOpts -jar minecraft_server*.jar nogui
fi
