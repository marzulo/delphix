#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# library.sh
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
set -xv
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


#
# Function to collect system info
# ARCH, OSTYPE, OSVERSION, MONGO_VERSION
#
function getSystemInfo {
	log "getSystemInfo: Getting system info"
    ARCH=$(uname -p)
    OSTYPE=$(uname)
    if [ "$OSTYPE" = "SunOS" ]; then
        OSTYPE="Solaris"
        OSVERSION=$(uname -v)
        OSSTR="$OSTYPE ${REV}(${ARCH} `uname -v`)"
    elif [ "$OSTYPE" = "AIX" ]; then
        OSSTR="$OSTYPE `oslevel` (`oslevel -r`)"
        OSVERSION=$(oslevel)
    elif [ "$OSTYPE" = "Linux" ]; then
        if [ -f /etc/redhat-release ]; then
            OSTYPE=RedHat
            OSVERSION=$(cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//')
        else
            die "Unsupported Linux Distro"
            OSTYPE=Unknown
            OSVERSION=Unsupported
        fi
    fi
    # Get Mongo version
    MONGO_VERSION=$(mongod --version | grep "db version" | awk '{print $3}')
    MONGO_STORAGE_ENGINE=
}

#
# Confirm that JQ is available on this system and add it to path
#
#
function initializeJQ {
    # Add jq to PATH for convenience. Note that it is appended to the front so we
    # will always use it even if jq is installed elsewhere on the machine
    PATH="$(dirname "$DLPX_BIN_JQ"):${PATH}"

    # Confirm that invoking jq works properly
    jq '.' <<< '{}' >/dev/null 2>/dev/null
    errorCheck 'Unable to initialize JQ'
}

#
# Quotes strings for use with JSON. Fails if the number of arguments is not
# exactly one because it will not do what the user likely expects.
#
function jqQuote {
   if [[ "$#" -ne 1 ]]; then
      log -d "Wrong number of arguments to jqQuote: $@"
   fi
   $DLPX_BIN_JQ -R '.' <<< "$1"
}

function purgeLogs {
   MaxFileSize=20971520
   DT=`date '+%Y%m%d%H%M%S'`
   log "Checking Log File Sizes ... "
   #
   # Debug Log 
   #
   file_size=`du -b ${DEBUG_LOG} | tr -s '\t' ' ' | cut -d' ' -f1`
   if [ $file_size -gt $MaxFileSize ];then   
      mv ${DEBUG_LOG} ${DEBUG_LOG}_${DT}
      touch ${DEBUG_LOG}
   fi
   #
   # Error Log 
   #
   file_size=`du -b ${ERROR_LOG} | tr -s '\t' ' ' | cut -d' ' -f1`
   if [ $file_size -gt $MaxFileSize ];then
      mv ${ERROR_LOG} ${ERROR_LOG}_${DT}
      touch ${ERROR_LOG}
   fi
}

#
# Keep for Library Verification ...
#
function hey {
   echo "there"
}


# Function that returns 0 if the replica is in a healthy state
function checkReplicationStatus {
    local json
    local mongo_state
    log "checkReplicationStatus Checking Status"
    # Get replicaset status
    log "\n mongo -u \"$MONGO_USER_NAME\" -p \"*****\" --host \"$MONGO_STANDBY_HOST\" --port \"$MONGO_PORT\" --authenticationDatabase admin --quiet --eval \"JSON.stringify(rs.status())\""
    json=$(mongo -u "$MONGO_USER_NAME" -p "$MONGO_USER_PASSWORD" --host "$MONGO_STANDBY_HOST" --port "$MONGO_PORT" --authenticationDatabase admin --quiet --eval "JSON.stringify(rs.status())")
    log "rs.status:\n$json"
    # Get hostname - need this to lookup the member status
    hostname=$(hostname)
    # We are intentionally supressing errors at .[] so that JQ does not throw an additional error when rs.status fails
    mongo_state=$(echo "$json" | jq ".members | .[]? | select(.self == true) | .state")
    errorLog "checkReplicationStatus warning: Unable to check Mongo status"
    if [[ mongo_state -ne 2 ]]; then
        errorLog "checkReplicationStatus warning: Mongo in invalid state ($mongo_state)"
        return 1
    fi
    log "checkReplicationStatus: Replication status is good"
    return 0
}


#
# Search for the value of the search_term in the delphixMongoConfig.dat file
# If value is found it is stored in the response_variable_name variable, if not
# the function dies with error
# Input params: config term (eg: TOOLKIT_VERSION, DB2VERSION, etc...) and
# response_variable_name
#
function getConfigValue {
	log "getConfigValue: Getting Config Value --> $search_term"
    if [ "$#" -ne 2 ]; then
            die "Mongo Config Error: Incorrect params to getConfigValue($@). Expecting search_term and response_variable_name"
    fi
    local search_term="$1"
    local response_variable_name="$2"
    if [ -z "$search_term" ]; then
            die "Mongo Config Error: Empty search param for getConfigValue()"
    fi
    if [ -z "$response_variable_name" ]; then
            die "Mongo Config Error: Empty response variable param for getConfigValue()"
    fi
    local response_value=$(grep -F "$search_term" $DLPX_DATA_DIRECTORY/$CONFIG_OUTPUT_FILE | awk 'NF>1{print $NF}')
    errorCheck "Mongo Config Error: Unable to find config value for $search_term"
    if [ -z "$response_value" ]; then
            die "Mongo Config Error: Unable to find config value for $search_term"
    fi
    # Set the named response variable to the appropriate value
    eval $response_variable_name=\$response_value
}

#
# Confirm that the value of the config param on the current host matches the
# snapshot
# Input params: config term and current value
#
function confirmConfigValue {
	log "confirmConfigValue: Confirming Config Value --> Search:$1 Current:$2"
    if [ "$#" -ne 2 ]; then
            die "Mongo Config Error: Incorrect params to confirmConfigValue($@)"
    fi
    local search_term="$1"
    local current_value="$2"
    if [ -z "$search_term" ]; then
            die "Mongo Config Error: Empty search_term for confirmConfigValue()"
    fi
    if [ -z "$current_value" ]; then
            die "Mongo Config Error: Empty current_value for confirmConfigValue()"
    fi
    # Store the snapshot value of the config in a temp variable
    getConfigValue "$search_term" "temp_variable"
    # Compare current value of the term against the temp_variable
    if [ "$current_value" != "$temp_variable" ]; then
            die "Mongo Config Error: $search_term of snapshot ($temp_variable) does not match this server ($current_value)"
    fi
}

#
# Search for the value of the search_term in the snapshotJson metadata
# If value is found it is stored in the response_variable_name variable, if not
# the function dies with error
# Input params: config term (eg: toolkitVersion, MongoVersion, etc...) and
# response_variable_name
#
function getSnapshotValue {
	log "getSnapshotValue: Getting Snapshot Value --> Search:$1 Response:$2"
    if [[ "$#" -ne 2 ]]; then
            log -d "Mongo Config Error: Incorrect params to getConfigValue($@). Expecting search_term and response_variable_name"
    fi
    local search_term="$1"
    local response_variable_name="$2"
    if [[ -z "$search_term" ]]; then
            log -d "Mongo Config Error: Empty search param for getConfigValue()"
    fi
    if [[ -z "$response_variable_name" ]]; then
            log -d "Mongo Config Error: Empty response variable param for getConfigValue()"
    fi
    local response_value
    #using the -r option to get unquoted raw output strings
    response_value=$($DLPX_BIN_JQ -r ".${search_term}" <<< "$MONGO_SNAPSHOT_METADATA")
    errorCheck "Mongo Config Error: Unable to find config value for $search_term (E1)\n$response_value"
    if [[ "$response_value" = "null" ]]; then
            log -d "Mongo Config Error: Unable to find config value for $search_term (E2)\n$response_value"
    fi
    if [[ -z "$response_value" ]]; then
            log -d "Mongo Config Error: Unable to find config value for $search_term (E3)\n$response_value"
    fi
    # Set the named response variable to the appropriate value
    eval $response_variable_name=\$response_value
}

#
# Confirm that the value of the config param on the current host matches the
# snapshotJson metadata
# Input params: config term and current value
#
function confirmSnapshotValue {

	log "confirmSnapshotValue: Confirming Snapshot Value --> Search:$1 Current:$2"
    if [[ "$#" -ne 2 ]]; then
            log -d "Mongo Config Error: Incorrect params to confirmConfigValue($@)"
    fi
    local search_term="$1"
    local current_value="$2"

    if [[ -z "$search_term" ]]; then
            log -d "Mongo Config Error: Empty search_term for confirmConfigValue()"
    fi
    if [[ -z "$current_value" ]]; then
            log -d "Mongo Config Error: Empty current_value for confirmConfigValue()"
    fi

    # Store the snapshot value of the config in a temp variable
    getSnapshotValue "$search_term" "temp_variable"
    # Compare current value of the term against the temp_variable
    if [[ "$current_value" != "$temp_variable" ]]; then
            log -d "Mongo Config Error: $search_term of snapshot ($temp_variable) does not match this server ($current_value)"
    fi
}


# Function to grab the primary instance port
function getPrimaryReplica() {
    local inputReplSetName=$1
    local allMongoInstances
    local chkmongod
    local currentInstance
    local currentPort
    local currentReplSetName
    local currentConfig
    local primaryReplica

    log "replSetName=$inputReplSetName"

    primaryReplica="none"
    allMongoInstances=$(ps -ef | grep [m]ongod)
    OLD_IFS="$IFS"
    IFS=$'\n'
    for currentInstance in $allMongoInstances
    do 
        chkmongod=$(echo "$currentInstance" | awk '{ print $8 }')
        log "chkmongod = $chkmongod"
        if [[ "$chkmongod" == *"mongod"* ]]
        then
            currentPort=$(echo "$currentInstance" | grep -Po '(?<=--port\s)[^\s]*' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            log "currentPort=$currentPort"
            if [[ -z $currentPort ]]; then
                # config files are specified with either -f or --config
                currentConfig=$(echo "$currentInstance" | grep -Po '(?<=-f\s|--config\s)[^\s]*')
                if [[ ! -z $currentConfig ]]; then
                    currentPort=$(cat $currentConfig | grep -v '^#' | grep '^port=' | sed -e 's/\port=//g')
                    if [[ -z $port ]]; then
                        currentPort=$(cat $currentConfig | grep -v '^#' | grep '^port:' | sed -e 's/\port://g')
                    else
                        currentPort=27017
                    fi
                else
                    #if not found set to default value
                    currentPort=27017
                fi
                currentPort=$(echo "$currentPort" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            fi
            log "currentPort=$currentPort"

            currentReplSetName=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD -port "$currentPort" admin -quiet -eval "db.isMaster().setName")
            log "currentReplSetName=$currentReplSetName"
            if [[ -n $(echo $currentReplSetName | grep 'authentication failed') ]]; then
                continue;
            fi
            if [[ -z $currentReplSetName ]]; then
               # config files are specified with either -f or --config
                currentConfig=$(echo "$currentInstance" | grep -Po '(?<=-f\s|--config\s)[^\s]*')
                if [[ ! -z $currentConfig ]]; then
                    currentReplSetName=$(cat $currentConfig | grep -v '^#' | grep '^replSetName=' | sed -e 's/\replSetName=//g')
                    if [[ -z $currentReplSetName ]]; then
                        currentReplSetName=$(cat $config | grep -v '^#' | grep '^replSetName:' | sed -e 's/\replSetName://g')
                    fi
                fi
                currentReplSetName=$(echo "$currentReplSetName" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            fi
            if [[ $(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD -port "$currentPort" admin -quiet -eval "rs.status().state") -eq 10 ]]; then
                continue;
            fi                
            if [[ ! -z "$currentReplSetName" ]] ; then
                if [[ "$inputReplSetName" = "$currentReplSetName" ]]; then
                    break;
                fi
            fi
        fi
    done
    primaryReplica=$(mongo -u $MONGO_USER_NAME -p $MONGO_USER_PASSWORD -port "$currentPort" admin -quiet -eval "db.isMaster().primary")
            log ">> Port : $currentPort"
            log ">> replSet : $currentReplSetName"
            log ">> primaryReplica : $primaryReplica"

    IFS="$OLD_IFS"
    echo $primaryReplica
}

# Function to grab the primary instance port
function mongoinstExists() {
    local portNum=$1
    local instances
    local chkmongod
    local port
    local instExists
    portNum=$1
    instExists=0
    instances=$(ps -ef | grep [m]ongod)
    OLD_IFS="$IFS"
    IFS=$'\n'
    for currentInstance in $instances
    do 
        chkmongod=$(echo "$currentInstance"| awk '{ print $8 }')
        if [[ "$chkmongod" == *"mongod"* ]]
        then
            port=$(echo "$currentInstance" | grep -Po '(?<=--port\s)[^\s]*' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            if [[ -z $port ]]; then
                # config files are specified with either -f or --config
                config=$(echo "$currentInstance" | grep -Po '(?<=-f\s|--config\s)[^\s]*')
                if [[ ! -z $config ]]; then
                    port=$(cat $config | grep -v '^#' | grep '^port=' | sed -e 's/\port=//g')
                    if [[ -z $port ]]; then
                        port=$(cat $config | grep -v '^#' | grep '^port:' | sed -e 's/\port://g')
                    fi
                fi
                port=$(echo "$port" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            fi

            if [ $port = $portNum ]
            then
                instExists = 1
                break;
            fi
        fi
    done
    IFS="$OLD_IFS"
    return $instExists
}

purgeLogs

###########################################################
## Test/Debug ...

#set -xv
#log "Log Debug Test ..."
#errorLog "Error Log Debug Test ..."
#getSystemInfo
#log "${ARCH},${OSTYPE},${OSVERSION}"
#json="pretty Name"
#log "JSON: ${json}"
#qjson=`jqQuote "$json"`
#log "JSON: ${qjson}"
#hey


