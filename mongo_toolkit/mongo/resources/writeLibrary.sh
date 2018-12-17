#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# writeLibrary.sh
#
# Library of common mongo toolkit functions ... 
#

###########################################################
## Required Environment Variables ...

#
# Delphix Supplied Environment Variables ...
# 
# DLPX_BIN_JQ=`which jq`
# DLPX_DATA_DIRECTORY
# 
# Additional Data Specific ...
#
# ? DLPX_TMP_DIRECTORY
#
# 
# Toolkit Specific ..
# 
DLPX_TOOLKIT_NAME="mongo" 
DLPX_LOG_DIRECTORY="/tmp"               # ="${DLPX_DATA_DIRECTORY}/.."

###########################################################
## Globals

TOOLKIT_VERSION="0.9.1"
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
CONFIG_OUTPUT_FILE="delphix_${DLPX_TOOLKIT_NAME}_config.dat"
ERROR_LOG="${DLPX_LOG_DIRECTORY}/delphix${DLPX_TOOLKIT_NAME}error.log"
DEBUG_LOG="${DLPX_LOG_DIRECTORY}/delphix${DLPX_TOOLKIT_NAME}debug.log"

###########################################################
## Functions ...

#
# Log infomation and die if option -d is used.
#
function log {
   Parms=$@
   die='no'
   if [[ $1 = '-d' ]]; then
      shift
      die='yes'
      Parms=$@
   fi
   #printf "[${TIMESTAMP}][DEBUG][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME
   printf "[${TIMESTAMP}][DEBUG][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME >>$DEBUG_LOG
   if [[ $die = 'yes' ]]; then
      exit 2
   fi
}

# Log error and write to the errorlog
function errorLog {
    log "$@"
    printf "[${TIMESTAMP}][ERROR][%s][%s]:[$Parms]\n" $DLPX_TOOLKIT_WORKFLOW $PGM_NAME >>$ERROR_LOG
}

# Write to log and errorlog before exiting with an error code
function die {
    errorLog "$@"
    exit 2
}

# Function to check for errors and die with passed in error message
function errorCheck {
    if [ $? -ne 0 ]; then
        die "$@"
    fi
}

if [ -z "$DLPX_LIBRARY_SOURCE" ]; then
        die "Mongo Library Error: Unable to load Mongo Library source "
fi

echo "$DLPX_LIBRARY_SOURCE" >${DLPX_DATA_DIRECTORY}/../delphixMongoFunctions.lib
errorCheck "Mongo Library Error: Unable to write Mongo Library to ${DLPX_DATA_DIRECTORY}/../delphixMongoFunctions.lib"

log "Wrote library.sh to ${DLPX_DATA_DIRECTORY}/../delphixMongoFunctions.lib"