#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="dropStagingFromPrimary.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

log "Removing Delphix staging host $MONGO_STANDBY_HOST:$MONGO_PORT from replica set"

# Grab the primary replication port and host
primaryReplica=$(getPrimaryReplica "$MONGO_REPLICASET")
primaryHost=$(echo $primaryReplica | cut -d ":" -f 1)
primaryPort=$(echo $primaryReplica | cut -d ":" -f 2)

log "\nmongo -u $MONGO_USER_NAME -p ***** --host "$primaryHost" --port "$primaryPort" --authenticationDatabase admin --quiet --eval \"rs.remove('${MONGO_STANDBY_HOST}:${MONGO_PORT}'))\""
output=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --host "$primaryHost" --port "$primaryPort" --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.remove('${MONGO_STANDBY_HOST}:${MONGO_PORT}'))")
log "Output: $output"
success=$(echo "$output" | jq '.ok')
if [ $success -eq 0 ]
then
        code=$(echo "$output" | jq '.code')
        errmsg=$(echo "$output" | jq '.errmsg')
        die "rs.add failed: Code: $code error:  $errmsg"
else
        log "rs.remove succeeded"
fi

log "\nmongo -u $MONGO_USER_NAME -p ***** --host $MONGO_STANDBY_HOST --port $MONGO_PORT --authenticationDatabase admin --quiet --eval \"printjson(rs.status())\""
output=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --host "$MONGO_STANDBY_HOST" --port "$MONGO_PORT" --authenticationDatabase admin --quiet --eval "printjson(rs.status())")
log "Output: $output"

exit 0