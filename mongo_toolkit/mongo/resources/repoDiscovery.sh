#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
#set -xv

#
# Program Name ...
#
PGM_NAME="repoDiscovery.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

# See if mongo service exist
#
INSTALLPATH=$(find /usr/bin -name mongod | head -1)
if [[ "$INSTALLPATH" = '' ]]; then
    # Install path not found - return empty repo config
    log "Install path /usr/bin/mongod not found"
    echo "[]" >"$DLPX_OUTPUT_FILE"
    exit 0
fi
log "INSTALLPATH=$INSTALLPATH"
# See if mongo shell exist
#
SHELLPATH=$(find /usr/bin -name mongo | head -1)
if [[ "$SHELLPATH" = '' ]]; then
    # Shell path not found - return empty repo config
    log "Shell path /usr/bin/mongod not found"
    echo "[]" >"$DLPX_OUTPUT_FILE"
    exit 0
fi
log "SHELLPATH=$SHELLPATH"

# Grab the primary replication port and host
#primaryReplica=$(getPrimaryReplica "$MONGO_REPLICASET")
primaryReplica=$(getPrimaryReplica)
log "Primary Replica : $primaryReplica"
primaryHost=$(echo $primaryReplica | cut -d ":" -f 1)
primaryPort=$(echo $primaryReplica | cut -d ":" -f 2)

# Query the current Mongo instance for version info
VERSION=$($SHELLPATH --host "$primaryHost" --port "$primaryPort" --quiet --eval "db.version()")

# If Mongod is not running we use the shell version number as the fallback
if [[ $? -ne 0 ]]; then
    log "$SHELLPATH --host ""$primaryHost"" --port ""$primaryPort"" --quiet --eval ""db.version()"""
    log "MongoDB not running / unable to connect mongodb to determine version"
    VERSION=$(mongo --version | awk '{print $4;}' | head -n 1)
    errorCheck "Found Mongo install ($INSTALLPATH) and shell ($SHELLPATH) but unable to query shell ($VERSION)"
    log "Version : $VERSION ( derived from shell version )"
else
    log "Version : $VERSION"
fi

log "DLPX_OUTPUT_FILE: $DLPX_OUTPUT_FILE"

# Assemble JSON and write output variables to output file
REPOSITORIES='[]'
CURRENT_REPO='{}'
PRETTYNAME="MongoDB (${VERSION})"
CURRENT_REPO=$(jq ".mongoInstallPath = $(jqQuote "$INSTALLPATH")" <<< "$CURRENT_REPO")
CURRENT_REPO=$(jq ".mongoShellPath = $(jqQuote "$SHELLPATH")" <<< "$CURRENT_REPO")
CURRENT_REPO=$(jq ".version = $(jqQuote "$VERSION")" <<< "$CURRENT_REPO")
CURRENT_REPO=$(jq ".prettyName = $(jqQuote "$PRETTYNAME")" <<< "$CURRENT_REPO")
REPOSITORIES=$(jq ". + [$CURRENT_REPO]" <<< "$REPOSITORIES")

echo "$REPOSITORIES" >> "$DLPX_OUTPUT_FILE"
errorCheck "Error writing to $DLPX_OUTPUT_FILE"

log "REPOSITORIES: $REPOSITORIES"

exit 0
