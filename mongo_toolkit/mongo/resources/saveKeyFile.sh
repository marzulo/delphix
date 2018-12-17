#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="saveKeyFile.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

# save keyfile only if path is specified
if [[ ! -z "$MONGO_KEYFILE_PATH" ]]; then

    log "Saving Keyfile $MONGO_KEYFILE_PATH to ${DLPX_DATA_DIRECTORY}/delphixKeyfile.pem"
    echo $MONGO_USER
    copyCommand=$(which cp)
    $copyCommand -f $MONGO_KEYFILE_PATH ${DLPX_DATA_DIRECTORY}/delphixKeyfile.pem
    errorCheck "Snapshot error: Unable to save keyfile $MONGO_KEYFILE_PATH to ${DLPX_DATA_DIRECTORY}/delphixKeyfile.pem"

fi

exit 0
