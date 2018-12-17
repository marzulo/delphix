#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
#set -xv

#
# Program Name ...
#
PGM_NAME="initiate.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

getSystemInfo

if [[ -z $MONGO_REPLICASET ]]; then
        getConfigValue "MONGO_REPLICASET" "MONGO_REPLICASET"
fi

output=$(mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.initiate())")

log "rs.initiate output: $output"

config="{_id: '$MONGO_REPLICASET', members:[{_id: 0, host: 'localhost:$MONGO_PORT'}]}"

log "Updating replicaset config with $config"

output=$(mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.reconfig(${config}, {force: true}))")

log "mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval \"JSON.stringify(rs.reconfig(${config}, {force: true}))\""

log "rs.reconfig output: $output"

exit 0