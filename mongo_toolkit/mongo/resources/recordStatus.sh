#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="recordStatus.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

getSystemInfo

# Grab the primary replication port and host
primaryReplica=$(getPrimaryReplica "$MONGO_REPLICASET")
primaryHost=$(echo $primaryReplica | cut -d ":" -f 1)
primaryPort=$(echo $primaryReplica | cut -d ":" -f 2)

# Lookup the current mongo storage engine
MONGO_STORAGE_ENGINE=$(mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval "JSON.stringify(db.serverStatus().storageEngine)")
MONGO_STORAGE_ENGINE=$(echo "$MONGO_STORAGE_ENGINE" | jq -r '.name')
# setting default to mmap as 2.6 does not have a value
if [[ -z "$MONGO_STORAGE_ENGINE" ]]; then
    MONGO_STORAGE_ENGINE='mmapv1'
fi

#MONGO_REPLICASET=$(mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.conf())")
#MONGO_REPLICASET=$(echo "$MONGO_REPLICASET" | jq -r '._id')
MONGO_REPLICASET=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD -port $MONGO_PORT --authenticationDatabase admin -quiet -eval "db.isMaster().setName")

#MONGO_KEYFILE_PATH is set in paramaters for staging. This value is not available on refresh or rewind, so in that case we grep the mongod process to identify whether the keyfile is set or not.
if [[ $MONGO_STAGING_SERVER_BOOL = true ]]; then
    if [[ ! -z "$MONGO_KEYFILE_PATH" ]]; then
        MONGO_AUTH='keyfile'
    fi
else
    instances=$(ps -ef | grep [m]ongod | awk '{ s = ""; for (i = 8; i <= NF; i++) s = s $i " "; print s }')
    log "instances=$instances"
    #$IFS (internal field separator) determines how Bash recognizes word boundaries
    #Temporarily set $IFS to \n (defaults to whitespace)
    OLD_IFS="$IFS"
    IFS=$'\n'
    for currentInstance in $instances; do
        dbPath=$(echo "$currentInstance" | grep -Po '(?<=--dbpath\s)[^\s]*')
        port=$(echo "$currentInstance" | grep -Po '(?<=--port\s)[^\s]*' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        keyfile=$(echo "$currentInstance" | grep -Po '(?<=--keyFile\s)[^\s]*')
        replSet=$(echo "$currentInstance" | grep -Po '(?<=--replSet\s)[^\s]*')
        if [[ $dbPath = ${DLPX_DATA_DIRECTORY} && $port = $MONGO_PORT ]]; then
            if [[ ! -z $keyfile ]]; then
                    log "keyfile not empty ($keyfile), set MONGO_AUTH='keyfile'"
                    MONGO_AUTH='keyfile'
            fi
            if [[ -z $MONGO_REPLICASET ]]; then
                    log "MONGO_REPLICASET not set, setting to $replSet"
                    MONGO_REPLICASET=$replSet
            fi
        fi
    done
    IFS="$OLD_IFS"
fi

output_string=$(printf "MONGO_STORAGE_ENGINE: $MONGO_STORAGE_ENGINE")
output_string=$(printf "${output_string}\nMONGO_AUTH: $MONGO_AUTH")
output_string=$(printf "${output_string}\nMONGO_REPLICASET: $MONGO_REPLICASET")
log "Writing config info to ${DLPX_DATA_DIRECTORY}/${CONFIG_OUTPUT_FILE}: $output_string"
# Write the output data to the config file - overwrites existing
echo "$output_string" >${DLPX_DATA_DIRECTORY}/${CONFIG_OUTPUT_FILE}

outputJSON='{}'
outputJSON=$($DLPX_BIN_JQ ".toolkitVersion = $(jqQuote "$TOOLKIT_VERSION")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".timestamp = $(jqQuote "$TIMESTAMP")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".architecture = $(jqQuote "$ARCH")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".osType = $(jqQuote "$OSTYPE")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".osVersion = $(jqQuote "$OSVERSION")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".mongoVersion = $(jqQuote "$MONGO_VERSION")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".delphixMount = $(jqQuote "$DLPX_DATA_DIRECTORY")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".mongoPort = $MONGO_PORT" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".storageEngine = $(jqQuote "$MONGO_STORAGE_ENGINE")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".mongoAuth = $(jqQuote "$MONGO_AUTH")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".replicaSet = $(jqQuote "$MONGO_REPLICASET")" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".journalInterval = $MONGO_JOURNAL_FLUSH" <<< "$outputJSON")
outputJSON=$($DLPX_BIN_JQ ".oplogSize = $MONGO_OPLOG_SIZE" <<< "$outputJSON")
if [[ -z $outputJSON ]]; then
        outputJSON='{}'
fi
log "writing outputJSON to $DLPX_OUTPUT_FILE --> $outputJSON"
printf "$outputJSON" > "$DLPX_OUTPUT_FILE"

exit 0