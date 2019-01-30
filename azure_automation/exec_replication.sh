#!/bin/bash

# A sample script for calls to the API. This one creates a Jet Stream bookmark.

##### Constants

# Describes a Delphix software revision.
# Please change version are per your Delphix Engine CLI, if different
#VERSION="1.8.0"
VERSION="1.7.0"


##### Default Values. These can be overwriten with optional arguments.
engine="10.200.0.39"
username="admin"
password="delphix"


##### Functions

# Help Menu
function usage {
	echo "Usage: exec_replication.sh [[-h] | options...] <name> <branch>"
	echo "Kick-off Delphix replication job"
	echo ""
	echo "Positional arguments"
	echo "  <name>"
	echo "  <branch>"
	echo ""
	echo "Optional Arguments:"
	echo "  -h                Show this message and exit"
	echo "  -d                Delphix engine IP address or host name, otherwise revert to default"
	echo "  -u USER:PASSWORD  Server user and password, otherwise revert to default"
}

# Create Our Session, including establishing the API version.
function create_session
{
	# Pulling the version into parts. The {} are necessary for string manipulation.
	# Strip out longest match following "."  This leaves only the major version.
	major=${VERSION%%.*}
	# Strip out the shortest match preceding "." This leaves minor.micro.
	minorMicro=${VERSION#*.}
	# Strip out the shortest match followint "." This leaves the minor version.
	minor=${minorMicro%.*}
	# Strip out the longest match preceding "." This leaves the micro version.
	micro=${VERSION##*.}

	# Quick note about the <<-. If the redirection operator << is followed by a - (dash), all leading TAB from the document data will be 
	# ignored. This is useful to have optical nice code also when using here-documents. Otherwise you must have the EOF be on a line by itself, 
	# no parens, no tabs or anything.

	echo "creating session..."
	result=$(curl -s -S -X POST -k --data @- http://${engine}/resources/json/delphix/session \
		-c ~/cookies.txt -H "Content-Type: application/json" <<-EOF
	{
		"type": "APISession",
		"version": {
			"type": "APIVersion",
			"major": $major,
			"minor": $minor,
			"micro": $micro
		}
	}
	EOF)

	check_result
}

# Authenticate the DE for the provided user.
function authenticate_de
{
	echo "authenticating delphix engine..."
	result=$(curl -s -S -X POST -k --data @- http://${engine}/resources/json/delphix/login \
		-b ~/cookies.txt -c ~/cookies.txt -H "Content-Type: application/json" <<-EOF
	{
		"type": "LoginRequest",
		"username": "${username}",
		"password": "${password}"
	}
	EOF)	

	check_result
}

## Execute replication

function exec_rep
{	
	result=$(curl -s -X POST -k --data @- http://${engine}/resources/json/delphix/replication/spec/${repSpec}/execute \
	    -b ~/cookies.txt -H "Content-Type: application/json" <<-EOF
	{
	}
	EOF)

	check_result
	
	echo "confirming job completed successfully..."
	# Get everything in the result that comes after job.
    temp=${result#*\"job\":\"}
    # Get rid of everything after
    jobRef=${temp%%\"*}


    result=$(curl -s -X GET -k http://${engine}/resources/json/delphix/job/${jobRef} \
    -b ~/cookies.txt -H "Content-Type: application/json")

    # Get everything in the result that comes after job.
    temp=${result#*\"jobState\":\"}
    # Get rid of everything after
    jobState=${temp%%\"*}

    check_result

    while [ $jobState = "RUNNING" ]
    do
    	sleep 1
    	result=$(curl -s -X GET -k http://${engine}/resources/json/delphix/job/${jobRef} \
	    -b ~/cookies.txt -H "Content-Type: application/json")

	    # Get everything in the result that comes after job.
	    temp=${result#*\"jobState\":\"}
	    # Get rid of everything after
	    jobState=${temp%%\"*}

	    check_result

    done

    if [ $jobState = "COMPLETED" ]
	then
		echo "successfully replicate changes in spec $repSpec"
	else
		echo "unable to replicate"
		echo result
	fi

}

# Check the result of the curl. If there are problems, inform the user then exit.
function check_result
{
	exitStatus=$?
	if [ $exitStatus -ne 0 ]
	then
	    echo "command failed with exit status $exitStatus"
	    exit 1
	elif [[ $result != *"OKResult"* ]]
	then
		echo ""
		echo $result
		exit 1
	fi
}

##### Main

while getopts "u:d:h" flag; do
	case "$flag" in
    	u )             username=${OPTARG%:*}
						password=${OPTARG##*:}
						;;
		d )             engine=$OPTARG
						;;
		h )             usage
						exit
						;;
		* )             usage
						exit 1
	esac

echo "OPTARG" $OPTARG ####

done


# Shift the parameters so we only have the positional arguments left
shift $((OPTIND-1))

# Check that there are 2 positional arguments
if [ $# != 1 ]
then
	usage
	exit 1
fi

# Get the one positional arguments
repSpec=$1

create_session
authenticate_de
exec_rep

