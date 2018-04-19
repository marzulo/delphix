#/bin/ksh
#================================================================================
#  File:	dwgrd.sql
#  Type:	UNIX/Linux korn-shell script
#  Date:	24-Mar 2016
#  Author:	Delphix
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  Copyright (c) 2016 by Delphix. All rights reserved.
# 
#  Description:
#
#	Shell-script intended to orchestrate a basic downgrade of an Oracle12c
#	or Oracle11g database to an earlier version.
#
#  Usage:
#
#	dwgrd.sh <new-ORACLE_HOME> <dlpx-Engine> <dlpx-EnvName> [ <ORACLE_BASE> ]
#
#	where:
#		<new-ORACLE_HOME>	to which this VDB is being downgraded
#		<dlpx-Engine>		Delphix Engine on which this VDB resides
#		<dlpx-EnvName>		Delphix Environment on which this VDB resides
#		<ORACLE_BASE>		under which this VDB presently resides
#
#  Modifications:
#	TGorman	24-Mar 2016	v1.0 first test version
#================================================================================
_dlpxUser=ora12102
#
#--------------------------------------------------------------------------------
# Validate command-line parameters specified...
#--------------------------------------------------------------------------------
case $# in
	4)      _newOraHome=$1
		_dlpxEngine=$2
		_dlpxEnvName=$3
		export ORACLE_BASE=$4
		;;
	3)      _newOraHome=$1
		_dlpxEngine=$2
		_dlpxEnvName=$3
		;;
	*)      echo "Usage: \"dwgrd.sh <new-ORACLE_HOME> <dlpx-Engine> <dlpx-EnvName> [ <ORACLE_BASE> ]\"; aborting..."
		echo "        <new-ORACLE_HOME> to which this VDB is being downgraded"
		echo "        <dlpx-Engine> Delphix Engine on which this VDB resides"
		echo "        <dlpx-EnvName> Delphix Environment on which this VDB resides"
		echo "        <ORACLE_BASE> under which this VDB presently resides"
		exit 1
		;;
esac
#
#--------------------------------------------------------------------------------
# Verify that ORACLE_SID, ORACLE_BASE, and ORACLE_HOME are set...
#--------------------------------------------------------------------------------
if [[ "${ORACLE_SID}" = "" ]]
then    
	echo "ORACLE_SID is not set; aborting..."
	exit 1
fi 
if [[ "${ORACLE_HOME}" = "" ]]
then    
	echo "ORACLE_HOME is not set; aborting..."
	exit 1
fi 
if [[ "${ORACLE_BASE}" = "" ]]
then    
	echo "ORACLE_BASE is not set; aborting..."
	exit 1
fi
if [ ! -d ${ORACLE_BASE} ]
then
	echo "ORACLE_BASE directory \"${ORACLE_BASE}\" not found; aborting..."
	exit 1
fi
if [ ! -d ${_newOraHome} ]
then
	echo "New ORACLE_HOME directory \"${_newOraHome}\" not found; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Verify how the downgrade is going to be performed...
#--------------------------------------------------------------------------------
echo ""
echo "downgrading ORACLE_SID \"${ORACLE_SID}\""
echo "from ORACLE_BASE \"${ORACLE_BASE}\", ORACLE_HOME \"${ORACLE_HOME}\", LD_LIBRARY_PATH \"${LD_LIBRARY_PATH}\""
echo "to ORACLE_HOME \"${_newOraHome}\""
echo ""
#
#--------------------------------------------------------------------------------
# Call the "catdwgrd" script from the "old" ORACLE_HOME...
#--------------------------------------------------------------------------------
sqlplus / as sysdba << __EOF0__
whenever oserror exit failure
shutdown immediate
whenever sqlerror exit failure
startup downgrade
drop user sysman cascade;
@?/rdbms/admin/catdwgrd
whenever sqlerror continue
shutdown immediate
exit success
__EOF0__
if (( $? != 0 ))
then
	echo "Downgrade operations failed; aborting..."
	exit 1
fi
echo "Downgrade script completed successfully"
#
#--------------------------------------------------------------------------------
# Save a copy of the Oracle initialization parameter file to "/tmp"...
#--------------------------------------------------------------------------------
cp ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora /tmp
if (( $? != 0 ))
then    
	echo "copy of init${ORACLE_SID}.ora from \"${ORACLE_HOME}/dbs\" to \"/tmp\" failed; aborting..."
	exit 1
fi
#
#--------------------------------------------------------------------------------
# Save "old" settings of ORACLE_HOME and ORACLE_BASE and set "new" settings for
# ORACLE_HOME and PATH to the downgraded version...
#--------------------------------------------------------------------------------
_oldOraBase=${ORACLE_BASE}
_oldOraHome=${ORACLE_HOME}
export ORACLE_HOME=${_newOraHome}
export PATH=${ORACLE_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
#
#--------------------------------------------------------------------------------
# If there is no "init.ora" file for the database in the ORACLE_HOME of the lower
# database version, then copy the saved-off copy of the Oracle initialization
# parameter file from the higher version.
#
# NOTE: please be aware that this could cause trouble with unrecognized parameters
#--------------------------------------------------------------------------------
if [ ! -f ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora ]
then
	cp /tmp/init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs
	if (( $? != 0 ))
	then
		echo "copy of init${ORACLE_SID}.ora from \"/tmp\" to \"${ORACLE_HOME}/dbs\" failed; aborting..."
		exit 1
	fi 
fi
#
#--------------------------------------------------------------------------------
# Log into the newly-downgraded database and run the "reload" script to ensure
# that the data dictionary views have the correct values for this version...
#--------------------------------------------------------------------------------
sqlplus / as sysdba << __EOF1__
whenever oserror exit failure
whenever sqlerror exit failure
startup upgrade
@?/rdbms/admin/catrelod
whenever sqlerror continue
shutdown immediate
exit success
__EOF1__
if (( $? != 0 ))
then
	echo "Reload operations failed; aborting..."
	exit 1
fi
echo "Reload script completed successfully"
#
#--------------------------------------------------------------------------------
# Log into the newly-downgraded database normally and recompile any invalid
# objects...
#--------------------------------------------------------------------------------
sqlplus / as sysdba << __EOF2__
whenever oserror exit failure
whenever sqlerror exit failure
startup
@?/rdbms/admin/utlrp
exit success
__EOF2__
if (( $? != 0 ))
then
	echo "Recompile operations failed; aborting..."
	exit 1
fi
echo "Recompile operations completed successfully"
#
#--------------------------------------------------------------------------------
# Connect into the CLI of the Delphix Engine and finish the downgrade...
#--------------------------------------------------------------------------------
_dlpxCliCmds="/sourceconfig select ${ORACLE_SID}; update; set repository=\"${_dlpxEnvName}/'${ORACLE_HOME}'\"; commit; exit"
echo "Delphix CLI commands=\"${_dlpxCliCmds}\""
ssh ${_dlpxUser}@${_dlpxEngine} "${_dlpxCliCmds}"
if (( $? != 0 ))
then
	echo "SSH to Delphix CLI failed; aborting..."
	exit 1
fi
echo "reassignment of ORACLE_HOME within Delphix completed successfully"
#
#--------------------------------------------------------------------------------
# Finished...
#--------------------------------------------------------------------------------
echo "Downgrade completed successfully"
exit 0
