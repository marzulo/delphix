#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="checkOwnership.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

instanceExist=$(ps -ef | grep "\-\-port $MONGO_PORT")
if [[ $instanceExist != "" ]]; then
    deleteDBPath=$(echo $instanceExist | awk '{for (i=1;i<=NF;i++) if ($i == "--dbpath") {print $(i+1)}}')
    if [[ "${DLPX_DATA_DIRECTORY}" == "$deleteDBPath" ]]; then
	echo "true" > "$DLPX_OUTPUT_FILE"
    else
	echo "false" > "$DLPX_OUTPUT_FILE"
    fi
else
    echo "true" > "$DLPX_OUTPUT_FILE"
fi
exit 0