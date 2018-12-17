#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="addStagingToPrimary.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

# Grab the host we are running this script on
hostname=$(hostname)
log "Current host : $hostname"

# Grab the primary replication port and host
primaryReplica=$(getPrimaryReplica "$MONGO_REPLICASET")
log "Primary Replica : $primaryReplica"
primaryHost=$(echo $primaryReplica | cut -d ":" -f 1)
primaryPort=$(echo $primaryReplica | cut -d ":" -f 2)

#For MongodDB  <= 2.8, need to specify an unused _id value in the replica set
log "\n mongo -u $MONGO_USER_NAME -p ***** --host "$primaryHost" --port "$primaryPort" --authenticationDatabase admin --quiet --eval \"printjson(JSON.stringify(rs.status()))"\"
json=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --host "$primaryHost" --port "$primaryPort" --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.status())")

log "rs.status:\n$json"
#_id An integer identifier of every member in the replica set. Values must be between 1 and 255 inclusive.
#see https://docs.mongodb.org/manual/reference/replica-configuration/#rsconf.members[n]._id
for i in {0..255}; do
    member=$(echo "$json" | jq ".members | .[] | select(._id == $i)")
    if [ -z "$member" ]; then
        new_id=$i
        log "New ID for staging instance : $new_id"
        break
    else
        log "Member $i : Already Exists "
    fi
done

if [ -z "$new_id" ]; then
    die "no valid ids available in replica set"
fi

log "Adding Delphix staging host $MONGO_STANDBY_HOST:${MONGO_PORT} to replica set with _id=$new_id"
log "\n mongo -u $MONGO_USER_NAME -p ***** --host $primaryHost --port $primaryPort --authenticationDatabase admin --quiet --eval \"JSON.stringify(rs.add({host:'${MONGO_STANDBY_HOST}:${MONGO_PORT}', priority: 0, hidden: true, _id: $new_id}))\""
output=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --host $primaryHost --port $primaryPort --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.add({host:'${MONGO_STANDBY_HOST}:${MONGO_PORT}', priority: 0, hidden: true, _id: $new_id}))")
success=$(echo "$output" | jq '.ok')
#Code 103 = Found two member configurations with same host field, meaning staging server already added
if [ $success -eq 0 ]
then
    code=$(echo "$output" | jq '.code')
    errmsg=$(echo "$output" | jq '.errmsg')
    log "Failed : rs.add({host:\'$MONGO_STANDBY_HOST:${MONGO_PORT}\', priority: 0, hidden: true, _id: $new_id})"
    die "rs.add failed: Code: $code error:  $errmsg"
else
    log "Success : rs.add({host:\'$MONGO_STANDBY_HOST:${MONGO_PORT}\', priority: 0, hidden: true, _id: $new_id})"
fi

exit 0
