#/bin/bash

./cmd.sh "say SERVER BACKUP STARTING. Server going readonly..."
./cmd.sh "save-off"
./cmd.sh "save-all"

# Run your backup command here. Here is an example using SARDELKA
docker run --name backup -v "$(pwd)/backup.config":/sardelka/backup.config -v "$(pwd)/backup.schedule":/sardelka/backup.schedule  -v $(pwd)/world":/source -v $(pwd)/backups/:/backups alexivkin/sardelka

sleep 2
./cmd.sh "save-on"
./cmd.sh "say SERVER BACKUP DONE. Server going read-write..."
