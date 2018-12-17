#!/bin/bash
#v1.1
#2018-04-20 Hims
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Intialization

DMIP=192.168.172.141
DMPORT=8282
DMUSER=delphix_admin
DMPASS=Delphix_123
JOBID=2
DELAYTIMESEC=5
STATUS=""
JOBSTATUS=""
CURRTIMESTAMP=$(date +"%Y.%m.%d.%S.%N")


#########################################################
##   Login authetication and autokoen capture
DMURL="http://${DMIP}:${DMPORT}/masking/api"
echo "Authenticating on ${DMURL}"

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
myLoginToken=`echo "${STATUS}" | jq --raw-output '.Authorization'`

if [  $myLoginToken == null ];then
        echo "Authentication FAILED : LoginToken" $myLoginToken
else
        echo "Authentication SUCCESS : LoginToken" $myLoginToken
fi

#########################################################
##   Firing job

BaseURL="http://${DMIP}:${DMPORT}"

echo Getting Masking Engine ${BaseURL} Log at ${CURRTIMESTAMP}

curl -v -s ${BaseURL}/dmsuite/login.do -c ~/cookies.txt -d "userName=${DMUSER}&password=${DMPASS}"
curl -v -s -X GET ${BaseURL}/dmsuite/logsReport.do -b ~/cookies.txt > /dev/null
curl -v -s -o ${CURRTIMESTAMP}.info.log -X GET ${BaseURL}/dmsuite/logsReport.do?action=download -b ~/cookies.txt
###
############## E O F ####################################
