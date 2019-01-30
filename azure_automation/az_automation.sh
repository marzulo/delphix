#!/bin/bash

##stop Delphix VM on azure

echo "####### Kick-off start of Delphix Engine #######"

./azure_cli_start_stop.sh start

echo "####### Checking the state of Target Delphix Engine #######"

st_time=`date +"%d-%b-%Y %H:%M:%S"`
echo $st_time

#sleep 250

until $(curl --output /dev/null --silent --head --fail http://172.16.5.4); do
 echo "trying to reach Delphix VM"
    sleep 10
done
echo "able to reach Delphix VM"

et_time=`date +"%d-%b-%Y %H:%M:%S"`
echo $et_time

echo "####### kicking-off Delphix replication #######"

./exec_replication.sh REPLICATION_SPEC-1


echo "####### Kick-off stop of Delphix Engine #######"

./azure_cli_start_stop.sh stop

exit 0