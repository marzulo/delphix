#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="startStaging.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

# Check for dsource directory and make if not there
hostname=$(hostname)
if [[ ! -z $MONGO_KEYFILE_PATH ]]
then
    keyFileName=$(basename $MONGO_KEYFILE_PATH)
    log "Keyfile : $MONGO_KEYFILE_PATH"
    if [[ -e ${DLPX_DATA_DIRECTORY}/${keyFileName} ]]; then
        die "Staging Mongo instance already running at: $hostname: $MONGO_PORT"
    fi
fi

mongoinstExists $MONGO_PORT

if [ $? -ne 0 ]
then
    die "Mongo instance already running at: $hostname: $MONGO_PORT"
fi

if [[ -d $DLPX_DATA_DIRECTORY ]]; then
	log "Directory $DLPX_DATA_DIRECTORY already exist"
else
	mkdir $DLPX_DATA_DIRECTORY
	errorCheck "Error making directory $DLPX_DATA_DIRECTORY"
fi	

mongoCommand="mongod --logpath ${DLPX_DATA_DIRECTORY}/mongod.log --fork --dbpath $DLPX_DATA_DIRECTORY --journal --journalCommitInterval $MONGO_JOURNAL_FLUSH --replSet $MONGO_REPLICASET --oplogSize $MONGO_OPLOG_SIZE --port $MONGO_PORT"

# If storage engine is anything but mmap we need to add it explicitly. This is because --storageEngine is not a valid param for 2.6
if [[ "$MONGO_STORAGE_ENGINE" != "mmapv1" ]]; then
    mongoCommand="$mongoCommand --storageEngine $MONGO_STORAGE_ENGINE"
fi

# Add keyfile only if path is specified
if [[ ! -z "$MONGO_KEYFILE_PATH" ]]; then
    mongoCommand="$mongoCommand --keyFile $MONGO_KEYFILE_PATH"
fi

# Add bind ip if specified
if [[ ! -z "MONGO_BIND_IP" ]]; then
    mongoCommand="$mongoCommand --bind_ip $MONGO_BIND_IP"
fi


log "Starting Standby Instance:\n$mongoCommand"
log "\n $mongoCommand"
output=$($mongoCommand)
errorCheck "Startup of the staging instance: $MONGO_PORT"
log "$output"

completed_code=1
while [[ $completed_code -ne 0 ]]
do
    sleep 10
    checkReplicationStatus
    completed_code=$?
done

exit 0