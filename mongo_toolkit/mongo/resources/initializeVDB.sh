#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
#set -xv

#
# Program Name ...
#
PGM_NAME="initializeVDB.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

STATUS_FILE=${DLPX_DATA_DIRECTORY}/status-${VDB_GUID}

# Making sure the sentinel file exists.
touch ${STATUS_FILE}
