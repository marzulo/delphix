#!/bin/bash
#v1.1
#2018-04-20 Hims
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Intialization

DMIP=52.55.56.229
DMPORT=8282
DMUSER=admin
DMPASS=Admin-12
JOBID=1
DELAYTIMESEC=5
STATUS=""
JOBSTATUS=""


#########################################################
##   Login authetication and autokoen capture
DMURL="http://${DMIP}:${DMPORT}/masking/api"
echo "Authenticating on ${DMURL}"

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
myLoginToken=`echo "${STATUS}" | jq --raw-output '.Authorization'`

if [  $myLoginToken == null ];then
        echo "Authentication FAILED : LoginToken" $myLoginToken
else
        echo "Authentication SUCCESS : LoginToken" $myLoginToken
fi

#########################################################
##   Firing job

echo "Executing job ${JOBID}"
STATUS=`curl -sX POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${myLoginToken}" -d "{ \"jobId\": ${JOBID} }" "${DMURL}/executions"`
#echo ${STATUS} | jq "."
EXID=`echo "${STATUS}" | jq --raw-output ".executionId"`
echo "Execution Id: ${EXID}"
JOBSTATUS=`echo Initial status "${STATUS}" | jq --raw-output ".status"`
JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
sleep ${DELAYTIMESEC}
#########################################################
##  Getting Job status
echo "*** waiting for status *****"
STATUS=`curl -sX GET --header 'Accept: application/json' --header "Authorization: ${myLoginToken}"  ${DMURL}/executions/${EXID}`
#echo ${STATUS} | jq "."
JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
echo "***  pinging for status >>>> " ${JOBSTATUS}

#########################################################
## waiting while checking job status

while [[ ${JOBSTATUS} == "RUNNING" ]]; do
				STATUS=`curl  -sX GET --header 'Accept: application/json' --header "Authorization: ${myLoginToken}"  ${DMURL}/executions/${EXID}`
				#echo ${STATUS} | jq "."
				JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
        echo "Current status as of" $(date)":"${JOBSTATUS}
        sleep ${DELAYTIMESEC}
done

#########################################################
##  Producing final status

if [ ${JOBSTATUS} == "SUCCEEDED" ]; then
        echo "Masking job(s) SUCCEDED"
        exit 1
else
        echo "Masking job(s) FAILED"
        exit 1
fi
############## E O F ####################################
