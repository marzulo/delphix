#!/bin/bash

#######################################################################################################################################################################
####  A sample script for calls to the Delphix and AWS API. This one starts Secondary Engine, replicate from primary to secondary and then stops Secondary Engine #####
################################################################## PRE-REQUISITES for this script #####################################################################
##################                 Install AWS CLI - https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html          ############################## 
##################        Install jq - wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64	                 ############################## 
##################              	   chmod +x ./jq																					 ##############################
##################            	       cp jq /usr/bin																					 ##############################
##################                         Create Delphix replication spec from Primary to Secondary                                     ##############################
##################                  Install curl (If not present on the box)															 ##############################
#######################################################################################################################################################################

##### Constants

# Describes a Delphix software revision.
# Please change version are per your Delphix Engine CLI, if different
VERSION="1.7.0"


##### Default Values. These can be overwriten with optional arguments.
username="admin"
password="delphix"


##### Functions

##########################################################################
###########		         FUNCTION - Turn On Debugging        #############
##########################################################################

function DEBUG()
{
if [[ $debugflag == 'debug' ]]
	then
		_DEBUG="on"
	fi
		
 [ "$_DEBUG" == "on" ] &&  $@
 
 exitStatus=0
 
 }



##########################################################################
###########					 FUNCTION - USAGE		  		 #############
##########################################################################

function usage {
	echo "Usage: delphix_aws_backup_automation_v1.sh [[-p] <IP or InstID> [-s] <AWS InstID> [-h] ] <rep-spec-name> debug (optional)"
	echo ""
	echo "Manage Secondary Delphix Engine in AWS with Delphix Replication"
	echo ""
	echo "Positional argument <rep-spec-name>"
	echo ""
	echo "  -h                Show this message and exit"
	echo "  -p                AWS Primary Delphix Engine InstanceID or IP address"
	echo "  -s                AWS Secondary Delphix Engine InstanceID"
	echo "Optional Arguments:"
	echo "  -u USER:PASSWORD  Primary Delphix Engine admin username and password, otherwise revert to default"
	echo " debug              Pass keyword <debug> after spec name to run script in debug mode"
}

##########################################################################
############## FUNCTION TO CREATE SESSION WITH PRIMARY ENGINE  ###########
##########################################################################

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
	
	DEBUG echo "##########################################################################################"
	DEBUG echo "$LINENO ###########   [2] FUNCTION CREATE SESSION WITH PRIMARY ENGINE - STARTED  #########"
	DEBUG echo "##########################################################################################"
	
	result=$(curl -s -S -X POST -k --data @- http://${primary_engine}/resources/json/delphix/session \
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
		
	DEBUG echo -e "$LINENO ########### API RESULT TO CREATE SESSION ##########\n" $result
	
	DEBUG echo "#########################################################################################"
	DEBUG echo "$LINENO ########### [2] FUNCTION CREATE SESSION WITH PRIMARY ENGINE - COMPLETED #########"
	DEBUG echo "#########################################################################################"
		
	check_result
}

##########################################################################
########### FUNCTION TO AUTHENTICATE PRIMARY ENGINE CREDENTIALS ##########
##########################################################################

function authenticate_de
{
	echo "authenticating delphix engine..."
	
	DEBUG echo "####################################################################################"
	DEBUG echo "$LINENO ###########   [3] FUNCTION AUTHENTICATE PRIMARY ENGINE - STARTED  #########"
	DEBUG echo "####################################################################################"
	
	result=$(curl -s -S -X POST -k --data @- http://${primary_engine}/resources/json/delphix/login \
		-b ~/cookies.txt -c ~/cookies.txt -H "Content-Type: application/json" <<-EOF
	{
		"type": "LoginRequest",
		"username": "${username}",
		"password": "${password}"
	}
	EOF)	
	
	DEBUG echo -e "$LINENO ########### API RESULT TO AUTHENTICATE PRIMARY ENGINE ##########\n" $result
	
	DEBUG echo "###################################################################################"
	DEBUG echo "$LINENO ########### [3] FUNCTION AUTHENTICATE PRIMARY ENGINE - COMPLETED #########"
	DEBUG echo "###################################################################################"

	check_result
}

##########################################################################
####### FUNCTION TO EXECUTE REPLICATION FROM PRIMARY TO SECONDARY ########
##########################################################################

function execute_replication
{	
    #### Waiting for Delphix Services to come online before starting replication ####
    
DEBUG echo "########################################################################################################"
DEBUG echo "$LINENO ########### [6] FUNCTION TO EXECUTE REPLICATION FROM PRIMARY TO SECONDARY - STARTED  ##########"
DEBUG echo "########################################################################################################"
    
  	echo "###### Waiting for Delphix services to come online ######"

	until $(curl --output /dev/null --silent --head --fail http://$secondary_engine); do
 	echo "Waiting for Delphix services to come online"
    sleep 10
	done

	echo "###### All Delphix services are online ######"
	
	## Check is replication pec list is passed
	
	for repSpecName in $(echo $repSpecList | sed "s/,/ /g")
    do
	
	DEBUG echo "$LINENO ########### Getting replication reference for spec $repSpecName ###########"

  get_spec_ref=$(curl -s -X GET -k http://${primary_engine}/resources/json/delphix/replication/spec \
	    -b ~/cookies.txt -H "Content-Type: application/json")
		
	check_result
	
	DEBUG echo -e "$LINENO ########### Replication SPEC NAME ###########\n" $repSpecName
	DEBUG echo -e "$LINENO ########### API result to list replication specs ###########\n" $get_spec_ref
	
	rep_spec_ref=$(echo $get_spec_ref | jq -r --arg repSpecName "$repSpecName" '.result[]| select(.name == $repSpecName) | .reference')
	
	DEBUG echo -e "$LINENO ########### Extracting replication reference for spec $repSpecName from last API call ###########\n" $rep_spec_ref
	
	exec_rep=$(curl -s -X POST -k --data @- http://${primary_engine}/resources/json/delphix/replication/spec/${rep_spec_ref}/execute \
	    -b ~/cookies.txt -H "Content-Type: application/json" <<-EOF
	{
	}
	EOF)

	check_result
	
	DEBUG echo -e "$LINENO ########### API result for executing replication for spec $repSpecName ###########\n" $exec_rep
	
	getrepstat=$(echo $exec_rep | jq -r '.status')			

	echo "##### GET Replication Job Status for spec $repSpecName ##### - $getrepstat"

	#### Check if replication job failed and exit from script

	if [ $getrepstat != "OK" ]; then 

  	  getstatdetail=$(echo $exec_rep | jq -r '.error.details')
    
  	  echo "Replication Spec ${repSpecName} terminated with error ${getstatdetail}"
   	  
   	  # shutdown Target even if it fails
   	  # If want to terminate process here without shutting down target, add exit 1 here.
   
	fi

	#### Get Replication Job ID ####
    
    jobRef=$(echo $exec_rep | jq -r '.job')
    
    echo "#### Replication JOB ID for spec $repSpecName ####" $jobRef

    get_rep_status=$(curl -s -X GET -k http://${primary_engine}/resources/json/delphix/job/${jobRef} \
    -b ~/cookies.txt -H "Content-Type: application/json")
    
    DEBUG echo -e "$LINENO ########### API result for replication status ###########\n" $get_rep_status
    
    jobState=$(echo $get_rep_status | jq -r '.result.jobState')
    
    echo "##### Initial Status of Delphix Replication Job for spec $repSpecName #####" $jobState

    check_result
    
    percentComplete=0

    while [ $jobState = "RUNNING" ]
    do        
    	sleep 5
    	
    	get_rep_status=$(curl -s -X GET -k http://${primary_engine}/resources/json/delphix/job/${jobRef} \
	    -b ~/cookies.txt -H "Content-Type: application/json")
	    
	        DEBUG echo -e "$LINENO ########### API result for replication status in loop ###########\n" $get_rep_status
    
    	jobState=$(echo $get_rep_status | jq -r '.result.jobState')
    	
    	DEBUG echo -e "$LINENO ########### Replication Job State ###########\n" $jobState

    	percentComplete=$(echo $get_rep_status | jq -r '.result.percentComplete')
    	
    	echo "Current Status of Delphix Replication Job for spec $repSpecName - " $jobState "- $percentComplete% completed"

	    check_result

    done
    
    echo "##### Final Status of Delphix Replication Job for spec $repSpecName #####" $jobState
    
    done
    

    if [ $jobState = "COMPLETED" ]
	then
		echo "##### Successfully replicate changes from Primary Engine (Inst:${primaryengineInstID}; IP:${primary_engine}) TO Secondary Engine (Inst:${secondaryengineInstID}; IP:${secondary_engine}) of spec $repSpecName #####"
	else
		echo "##### Unable to replicate changes #####"
		echo result
	fi
	
DEBUG echo "#########################################################################################################"
DEBUG echo "$LINENO ########### [6] FUNCTION TO EXECUTE REPLICATION FROM PRIMARY TO SECONDARY - COMPLETED  ##########"
DEBUG echo "#########################################################################################################"

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

######################################################################
####### FUNCTION TO GET PUBLIC IPs of ENGINES from InstanceID ########
######################################################################

function get_publicip ()
{

# Check if instance id passed or IP address is passed

if [ "$1" == "primary" ]; then

# If Instance ID is passed, fetch IP address

if [[ $primaryengineIPorInstID =~ ^i- ]]; then

DEBUG echo "########################################################################################"
DEBUG echo "$LINENO ########### [1] FUNCTION GET PUBLIC IP FOR PRIMARY ENGINE - STARTED ###########"
DEBUG echo "########################################################################################"

primaryengineInstID=$primaryengineIPorInstID

get_primary_pub_ip=$(aws ec2 describe-instances --instance-ids $primaryengineInstID)

DEBUG echo -e "$LINENO ########### API call result to fetch instance details of $1 engine ###########\n" $get_primary_pub_ip

primary_engine=$(echo $get_primary_pub_ip | jq -r '.Reservations[].Instances[].PublicIpAddress')

else

# If IP address is passed, use it

primary_engine=$primaryengineIPorInstID
 
fi

DEBUG echo -e "$LINENO ########### Public IP of $1 engine fetched ###########\n" $primary_engine

DEBUG echo "#########################################################################################"
DEBUG echo "$LINENO ########### [1] FUNCTION GET PUBLIC IP FOR PRIMARY ENGINE - COMPLETED ###########"
DEBUG echo "#########################################################################################"

elif [ "$1" == "secondary" ]; then

DEBUG echo "#########################################################################################"
DEBUG echo "$LINENO ########### [5] FUNCTION GET PUBLIC IP FOR SECONDARY ENGINE - STARTED ###########"
DEBUG echo "#########################################################################################"

get_secondary_pub_ip=$(aws ec2 describe-instances --instance-ids $secondaryengineInstID)

DEBUG echo -e "$LINENO ########### API call result to fetch instance details of $1 engine ###########\n" $get_secondary_pub_ip

secondary_engine=$(echo $get_secondary_pub_ip | jq -r '.Reservations[].Instances[].PublicIpAddress')

DEBUG echo -e "$LINENO ########### Public IP of $1 engine fetched ###########\n" $secondary_engine

DEBUG echo "############################################################################################"
DEBUG echo "$LINENO ########### [5] FUNCTION GET PUBLIC IP FOR SECONDARY ENGINE - COMPLETED ###########"
DEBUG echo "############################################################################################"

fi

}

##################################################################
####### FUNCTION TO CONTROL (START/STOP) SECONDARY ENGINE ########
##################################################################

function ctl_secondary_engine
{
 #### Stop Secondary Delphix Engine ####
 
  if [ "$1" == "stop" ]; then
  
  DEBUG echo "##############################################################################"
  DEBUG echo "$LINENO ########### [7] FUNCTION STOP SECONDARY ENGINE - STARTED  ###########"
  DEBUG echo "##############################################################################"

capture_state=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)

DEBUG echo -e "$LINENO ########### AWS API result to capture current status of secondary engine ###########\n" $capture_state

initial_state=$(echo $capture_state | jq -r '.InstanceStatuses[].InstanceState.Name')

DEBUG echo -e "$LINENO ########### Current status of secondary engine ###########\n" $initial_state

if [ "$initial_state" == "stopped" ]; then

echo "Delphix Engine Instance $secondaryengineInstID is already in stopped state"

else

echo "##### Stopping Target Delphix Engine instance: $secondaryengineInstID #####"

job_action=$(aws ec2 stop-instances --instance-ids $secondaryengineInstID)

DEBUG echo -e "$LINENO ########### AWS API result to stop secondary engine ###########\n" $job_action

vm_status=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)

DEBUG echo -e "$LINENO ########### AWS API result to check status of secondary engine ###########\n" $vm_status

vm_state=$(echo $vm_status | jq -r '.InstanceStatuses[].InstanceState.Name')

echo "Current Status of Delphix Engine Instance: " $vm_state

####### Track Delphix Engine Status after stop #####

while [ "$vm_state" != "stopped" ]
    do
    	sleep 5
    	
    	echo "Current Status of Delphix Engine Instance: " $vm_state
    	
    	vm_status=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)
    	
        DEBUG echo -e "$LINENO ########### AWS API result to check status of secondary engine ###########\n" $vm_status

		vm_state=$(echo $vm_status | jq -r '.InstanceStatuses[].InstanceState.Name')
		
		DEBUG echo -e "$LINENO ########### Status of secondary engine ###########\n" $vm_state


    done
    
    echo "###### Final Status of Delphix Engine instance: $secondaryengineInstID ######" $vm_state
    
    DEBUG echo "###############################################################################"
    DEBUG echo "$LINENO ########### [7] FUNCTION START SECONDARY ENGINE - COMPLETED ##########"
    DEBUG echo "###############################################################################"

fi

 #### Start Secondary Delphix Engine ####

elif [ "$1" == "start" ]; then

DEBUG echo "$LINENO #####################################################################"
DEBUG echo "$LINENO ########### [4] FUNCTION START SECONDARY ENGINE - STARTED ###########"
DEBUG echo "$LINENO #####################################################################"

capture_state=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)

DEBUG echo -e "$LINENO ########### AWS API result to capture current status of secondary engine ###########\n" $capture_state

initial_state=$(echo $capture_state | jq -r '.InstanceStatuses[].InstanceState.Name')

DEBUG echo -e "$LINENO ########### Current status of secondary engine ###########\n" $initial_state

if [ "$initial_state" == "running" ]; then

echo "Delphix Engine Instance $secondaryengineInstID is already in running state"

else

echo "##### Starting Target Delphix Engine instance: $secondaryengineInstID #####"

job_action=$(aws ec2 start-instances --instance-ids $secondaryengineInstID)

DEBUG echo -e "$LINENO ########### AWS API result to start secondary engine ###########\n" $job_action

vm_status=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)

DEBUG echo -e "$LINENO ########### AWS API result to check status of secondary engine ###########\n" $vm_status

vm_state=$(echo $vm_status | jq -r '.InstanceStatuses[].InstanceState.Name')

echo "Current Status of Delphix Engine Instance: " $vm_state

####### Track Delphix Engine Status after start #####

while [ "$vm_state" != "running" ]
    do
    	sleep 5
    	
    	echo "Current status of Delphix Engine Instance: " $vm_state
    	
    	vm_status=$(aws ec2 describe-instance-status --instance-ids $secondaryengineInstID --include-all-instances)
    	
    	DEBUG echo -e "$LINENO ########### AWS API result to check status of secondary engine ###########\n" $vm_status

		vm_state=$(echo $vm_status | jq -r '.InstanceStatuses[].InstanceState.Name')
		
		DEBUG echo -e "$LINENO ########### Status of secondary engine ###########\n" $vm_state

    done
    
    echo "###### Final Status of Delphix Engine Instance: $secondaryengineInstID ######" $vm_state
    
    DEBUG echo "$LINENO ########### [4] FUNCTION START SECONDARY ENGINE - COMPLETED ###########"

fi

fi

}

############## Main Code

while getopts "u:p:s:h" flag; do
	case "$flag" in
    	u )             username=${OPTARG%:*}
						password=${OPTARG##*:}
						;;
		p )             primaryengineIPorInstID=$OPTARG
						;;
		s )             secondaryengineInstID=$OPTARG
						;;
		h )             usage
						exit
						;;
		* )             usage
						exit 1
	esac

done


# Shift the parameters so we only have the positional arguments left
shift $((OPTIND-1))

# Check if there are 2 positional arguments, second is debug
if [ $# == 2 -a "$2" != "debug" ]
then
	usage
	exit 1
fi

if [ $# == 0 ]
then
	usage
	exit 1
fi

# Get the one positional arguments
repSpecList=$1
debugflag=$2

get_publicip "primary"
create_session
authenticate_de
ctl_secondary_engine "start"
get_publicip "secondary"
execute_replication
ctl_secondary_engine "stop"