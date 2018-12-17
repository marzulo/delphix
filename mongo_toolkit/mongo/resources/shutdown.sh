#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
#set -xv

#
# Program Name ...
#
PGM_NAME="shutdown.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

log "GUID: $VDB_GUID"
log "MONGO_KEYFILE_PATH: $MONGO_KEYFILE_PATH"
log "MONGO_REPLICASET: $MONGO_REPLICASET"

log "mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p ***** --authenticationDatabase admin --quiet --eval \"db.getSiblingDB('admin').shutdownServer({force: true})\""

output=$(mongo 127.0.0.1:$MONGO_PORT -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD --authenticationDatabase admin --quiet --eval "db.getSiblingDB('admin').shutdownServer({force: true})")
log "Shutting Down Mongo:\n$output"
exit 0
