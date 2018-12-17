#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="start.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

getSystemInfo

getConfigValue "MONGO_STORAGE_ENGINE" "MONGO_STORAGE_ENGINE"

if [[ ! -z "$MONGO_KEYFILE_PATH" ]]; then
    getConfigValue "MONGO_AUTH" "MONGO_AUTH"
fi

#getConfigValue "MONGO_REPLICASET" "MONGO_REPLICASET"

# Construct base command
mongoCommand="mongod --logpath ${DLPX_DATA_DIRECTORY}/mongod.log --fork --dbpath $DLPX_DATA_DIRECTORY --journal --journalCommitInterval $MONGO_JOURNAL_FLUSH --oplogSize $MONGO_OPLOG_SIZE --port $MONGO_PORT"

# If storage engine is anything but mmap we need to add it explicitly. This is because --storageEngine is not a valid param for 2.6
if [[ ! -z $MONGO_STORAGE_ENGINE ]] && [[ "$MONGO_STORAGE_ENGINE" != "mmapv1" ]]; then
        mongoCommand="$mongoCommand --storageEngine $MONGO_STORAGE_ENGINE"
fi

# If there is keyfile auth then enable it from the known keyfile location
if [[ "$MONGO_AUTH" == "keyfile" ]]; then
        mongoCommand="$mongoCommand --keyFile ${DLPX_DATA_DIRECTORY}/delphixKeyfile.pem"
fi

# Add bind ip if specified
if [[ ! -z "MONGO_BIND_IP" ]]; then
    mongoCommand="$mongoCommand --bind_ip $MONGO_BIND_IP"
fi

log "Starting Mongo VDB:\n$mongoCommand"
output=$($mongoCommand)
log "Result:\n$output"

#sleep 20

exit 0