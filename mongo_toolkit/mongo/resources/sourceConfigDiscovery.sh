#
# Copyright (c) 2018 by Delphix. All rights reserved.
#
#
##DEBUG## In Delphix debug.log
set -xv

#
# Program Name ...
#
PGM_NAME="sourceConfigDiscovery.sh"             # used in log and errorLog
#
# Load Library ...
#
eval "${DLPX_LIBRARY_SOURCE}"
log "Executing $PGM_NAME"
log "------------------------------------------------------- "

#add jq to the path
initializeJQ

# Check to see Mongo Version or install path are empty
if [[ "$MONGO_VERSION" = '' ]] || [[ "$MONGO_INSTALL_PATH" = '' ]]; then
        die 'MONGO_VERSION or MONGO_INSTALL_PATH not set when doing source config discovery'
fi

log "MONGO_VERSION      : $MONGO_VERSION"
log "MONGO_INSTALL_PATH : $MONGO_INSTALL_PATH"
# Find the mongo instances
#
instances=$(ps -ef | grep [m]ongod)
errorCheck "Error finding Mongo instances \n${instances}"

# Get configs for each instance
#
sourceConfigs='[]'
OLD_IFS="$IFS"
IFS=$'\n'
for currentInstance in $instances
do 
    chkmongod=$(echo "$currentInstance"| awk '{ print $8 }'); 
    if [[ $chkmongod == *"mongod"* ]]
    then
        log "Current Mongo Instance"
        log "$currentInstance"
        dbPath=$(echo "$currentInstance" | grep -Po '(?<=--dbpath\s)[^\s]*')
        port=$(echo "$currentInstance" | grep -Po '(?<=--port\s)[^\s]*' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	    replSet=$(echo "$currentInstance" | awk '{for (i=1;i<=NF;i++) if ($i == "--replSet") {print $(i+1)}}')
	    keyFilePath=$(echo "$currentInstance" | awk '{for (i=1;i<=NF;i++) if ($i == "--keyFile") {print $(i+1)}}')

        if [[ -z $dbPath ]] || [[ -z $port ]]; then
            # config files are specified with either -f or --config
            config=$(echo "$currentInstance" | grep -Po '(?<=-f\s|--config\s)[^\s]*')
            if [[ -z $dbPath ]] && [[ ! -z $config ]]; then
                    dbPath=$(cat $config | grep -v '^#' | grep '^dbpath=' | sed -e 's/\dbpath=//g')
		    else
                    #if not found set to default value
                    dbPath="/data/db"
            fi
            if [[ -z $port ]] && [[ ! -z $config ]]; then
                    port=$(cat $config | grep -v '^#' | grep '^port=' | sed -e 's/\port=//g')
                    if [[ -z $port ]]; then
                        port=$(cat $config | grep -v '^#' | grep '^port:' | sed -e 's/\port://g')
                    fi
            else
                    #if not found set to default value
                    port=27017
            fi
        fi
        log "dbPath = $dbPath, port=$port, replSet=$replSet, keyFilePath=$keyFilePath "

        primaryReplica=$(getPrimaryReplica $replSet)
        log "Primary Replica : $primaryReplica"
        if [ $primaryReplica = "none" ]
        then
            log "No mongo instance found on host"
            currentSourceConfig='{}'
            sourceConfigs=$(jq ". + [$currentSourceConfig]" <<< "$sourceConfigs")
        else
            primaryHost=$(echo $primaryReplica | cut -d ":" -f 1)
            primaryPort=$(echo $primaryReplica | cut -d ":" -f 2)
            myhostname=$(hostname)
            myhostname=$(echo $myhostname |cut -d "." -f 1)
            myprimaryHost=$(echo $primaryHost |cut -d "." -f 1)
            log "primaryHost=$primaryHost"
            log "primaryPort=$primaryPort"
            log "myhostname=$myhostname"
            log "myprimaryHost=$myprimaryHost"
            if [[ ! -z $myprimaryHost  ]]
            then
                if [ $myhostname  = $myprimaryHost ] && [ $port = $primaryPort ]
                then
                    prettyName="Mongo:${port} - $dbPath (Primary)"
                else
                    prettyName="Mongo:${port} - $dbPath"
                fi
            else
                prettyName="Mongo:${port} - $dbPath"
            fi
            log "prettyName=$prettyName"
            # Grab data path, port, & pretty name for display on environment screen
            
            currentSourceConfig='{}'
            currentSourceConfig=$(jq ".dbPath = $(jqQuote "$dbPath")" <<< "$currentSourceConfig")
            currentSourceConfig=$(jq ".mongoPort = $port" <<< "$currentSourceConfig")
            currentSourceConfig=$(jq ".replicaSet = $(jqQuote "$replSet")" <<< "$currentSourceConfig")
            currentSourceConfig=$(jq ".keyfilePath = $(jqQuote "$keyFilePath")" <<< "$currentSourceConfig")
            currentSourceConfig=$(jq ".prettyName = $(jqQuote "$prettyName")" <<< "$currentSourceConfig")
            sourceConfigs=$(jq ". + [$currentSourceConfig]" <<< "$sourceConfigs")
        fi
    fi
done
IFS="$OLD_IFS"

log "Source Configs: $sourceConfigs"
echo "$sourceConfigs" > "$DLPX_OUTPUT_FILE"
errorCheck "Error writing to $DLPX_OUTPUT_FILE"

exit 0
