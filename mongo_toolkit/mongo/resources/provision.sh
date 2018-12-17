#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
#set -xv

#
# Program Name ...
#
PGM_NAME="provision.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

getSystemInfo

if [[ -z "$MONGO_SNAPSHOT_METADATA" ]]; then
    log -d "Mongo Provisioning Error: Empty snapshot metadata ($MONGO_SNAPSHOT_METADATA)"
    exit 2
fi

log "MONGO_SNAPSHOT_METADATA=$MONGO_SNAPSHOT_METADATA"

snapshotVersion=$MONGO_SNAPSHOT_METADATA
confirmSnapshotValue "toolkitVersion" "$TOOLKIT_VERSION"
confirmSnapshotValue "architecture" "$ARCH"
confirmSnapshotValue "osType" "$OSTYPE"
confirmSnapshotValue "osVersion" "$OSVERSION"
confirmSnapshotValue "mongoVersion" "$MONGO_VERSION"

# Check if there is an existing instance on Mongo listening on that port number
log "Checking for existing Mongo instance at $MONGO_PORT"
#sudo lsof -iTCP -sTCP:LISTEN | grep mongo
mongoinstExists $MONGO_PORT
errorCheck "Mongo instance already running at: $hostname: $MONGO_PORT"

getSnapshotValue "storageEngine" "MONGO_STORAGE_ENGINE"

if [[ ! -z "$MONGO_KEYFILE_PATH" ]]; then
    getSnapshotValue "mongoAuth" "MONGO_AUTH"
fi
#getSnapshotValue "replicaSet" "MONGO_REPLICASET"

output_string=$(printf "MONGO_STORAGE_ENGINE: $MONGO_STORAGE_ENGINE")
output_string=$(printf "${output_string}\nMONGO_AUTH: $MONGO_AUTH")
#output_string=$(printf "${output_string}\nMONGO_REPLICASET: $MONGO_REPLICASET")
# Write the output data to the config file - overwrites existing
echo "$output_string" >${DLPX_DATA_DIRECTORY}/${CONFIG_OUTPUT_FILE}

prettyName="Mongo:$MONGO_PORT - ${DLPX_DATA_DIRECTORY}"
outputJSON='{}'
outputJSON=$($DLPX_BIN_JQ ".dbPath = $(jqQuote "$DLPX_DATA_DIRECTORY")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".mongoPort = $MONGO_PORT" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".prettyName = $(jqQuote "$prettyName")" <<< "$outputJSON")
log "writing outputJSON to DLPX_OUTPUT_FILE: $outputJSON"
printf "$outputJSON" > "$DLPX_OUTPUT_FILE"

completed_code=1

exit 0