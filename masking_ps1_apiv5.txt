#v1.2
#2018-04-20 Hims
#2018-10-29 Marzulo - Windows - PowerShell 3 & 5.1
#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
$d = Get-Date
echo "$d  Start Time ..."
#########################################################
## Delphix Masking Parameter Initialization
##
$DMIP='52.55.56.229'
$DMPORT=8282
$DMUSER='admin'
$DMPASS='Admin-12'
$APPLICATION = 'adv'
$JOBID=1
$DELAYTIMESEC=5
$STATUS=''
$JOBSTATUS=''

#########################################################
##                   DELPHIX CORP                      ##
#########################################################
echo "Running Masking JobID ${JOBID} for Application ${APPLICATION} ..."
#########################################################
##
##   Login authetication and token capture
##
$BaseURL="http://${DMIP}:${DMPORT}/masking/api"
echo "Authenticating on ${BaseURL}"
$results = (Invoke-WebRequest -Method POST -body "{ ""username"": ""${DMUSER}"", ""password"": ""${DMPASS}"" }" -Uri "${BaseURL}/login" -ContentType application/json)
#echo $results
$arr = @((echo $results | ConvertFrom-Json | ConvertTo-Json).split(' : '))
#echo $arr
$my2 = @($arr[7].split('}'))
#echo $my2
$myLoginToken=$my2[0] -replace "`n|`r|`""
echo "Authentication Successful: ${myLoginToken}"


#########################################################
##
##   Firing job
##
echo "Executing job ${JOBID}"
$results = (Invoke-WebRequest -Headers @{"Authorization" = "${myLoginToken}"} -Method POST -body "{ ""jobId"": ${JOBID} }" -Uri "${BaseURL}/executions" -ContentType application/json)
$exid0 = @((echo $results | ConvertFrom-Json | select executionId | ConvertTo-Json).split(': '))
$exid1 = @($exid0[7].split('}'))
$EXID = $exid1[0] -replace "`n|`r|`""
echo "Execution Id: ${EXID}"
$js0 = @((echo $results | ConvertFrom-Json | select status | ConvertTo-Json).split(': '))
$js1 = @($js0[7].split('}'))
$JOBSTATUS = $js1[0] -replace "`n|`r|`""
echo "Execution Id: ${EXID}"


#########################################################
##  Getting Job status
echo "*** waiting for status *****"
DO
{
  sleep ${DELAYTIMESEC}
  $d = Get-Date
  echo "$d  fetching status ..."
  $results = (Invoke-WebRequest -Headers @{"Authorization" = "${myLoginToken}"} -Method GET -Uri "${BaseURL}/executions/${EXID}" -ContentType application/json)
  $js0 = @((echo $results | ConvertFrom-Json | select status | ConvertTo-Json).split(': '))
  $js1 = @($js0[7].split('}'))
  $JOBSTATUS = $js1[0] -replace "`n|`r|`""
  $rt0 = @((echo $results | ConvertFrom-Json | select rowsTotal | ConvertTo-Json).split(': '))
  $rt1 = @($rt0[7].split('}'))
  $ROWSTOTAL = $rt1[0] -replace "`n|`r|`""
  $rm0 = @((echo $results | ConvertFrom-Json | select rowsMasked | ConvertTo-Json).split(': '))
  $rm1 = @($rm0[7].split('}'))
  $ROWSMASKED = $rm1[0] -replace "`n|`r|`""
  echo "STATUS: ${JOBSATUS} / Total Rows: ${ROWSTOTAL} / Rows Masked: ${ROWSMASKED}"
} While ($JOBSTATUS -contains "RUNNING")


#########################################################
##
##  Producing final status
##
$d = Get-Date
if ("${JOBSTATUS}" -eq "SUCCEEDED") {
   echo "Done at ${d} - Total Rows: ${ROWSTOTAL} / Rows Masked: ${ROWSMASKED}"
   exit 0
} else {
   echo "Masking job(s) Failed with ${JOBSTATUS} Status at ${d}"
   exit 1
}
