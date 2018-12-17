#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="status.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

# Get hostname - need this to lookup the member status
hostname=$(hostname)

log "Checking for instance --> $hostname:$MONGO_PORT"

# If Mongo process is not found we need to return the "off" code
current_instance=$(ps -ef | grep [m]ongod | grep "\--port $MONGO_PORT" | grep "\--dbpath ${DLPX_DATA_DIRECTORY}" | wc -l)
if [[ $current_instance -eq 0 ]]; then
    log "Unable to find Mongo instance on port $MONGO_PORT with dbpath ${DLPX_DATA_DIRECTORY}"
    printf "\"INACTIVE\"" > "$DLPX_OUTPUT_FILE"
    exit 0
fi
echo $MONGO_STATUS_TYPE
#if it is a VDB then exit with success
if [[ "$MONGO_STATUS_TYPE" = "virtual" ]]; then
    log "life is virtually good on port $MONGO_PORT"
    printf "\"ACTIVE\"" > "$DLPX_OUTPUT_FILE"
    exit 0
fi

# For staging servers we will check the replicaset status
json=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --port "$MONGO_PORT" --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.status())")


# We are intentionally supressing errors at .[] so that JQ does not throw an additional error when rs.status fails
mongo_state=$(echo "$json" | jq ".members | .[]? | select(.self == true) | .state")
errorCheck "Unable to check Mongo status ($mongo_state)\n$json"
if [[ $mongo_state -ne 2 ]]; then
        errorLog "Mongo in invalid state\n$json"
        printf "\"INACTIVE\"" > "$DLPX_OUTPUT_FILE"
        exit 2
fi

log "life is good at $hostname:$MONGO_PORT"
printf "\"ACTIVE\"" > "$DLPX_OUTPUT_FILE"
exit 0