#/bin/ksh
#================================================================================
#  File:	upgrd.sh
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
#	Shell-script intended to orchestrate a basic Oracle database upgrade
#	from 10g or 11g to a higher version.  For upgrades to Oracle12c, a
#	non-CDB database is created.
#
#  Usage:
#
#	upgrd.sh <new-ORACLE_HOME> <dlpx-Engine> <dlpx-EnvName> [ <ORACLE_BASE> ]
#
#	where:
#		<new-ORACLE_HOME>	to which this VDB is being upgraded
#		<dlpx-Engine>		Delphix Engine on which this VDB resides
#		<dlpx-EnvName>		Delphix Environment on which this VDB resides
#		<ORACLE_BASE>		under which this VDB presently resides
#
#  Modifications:
#	TGorman	24-Mar 2016	v1.0 first test version
#================================================================================
_dlpxUser=delphix_admin
#
#--------------------------------------------------------------------------------
# Validate command-line parameters specified...
#--------------------------------------------------------------------------------
case $# in
	4)	_newOraHome=$1
		_dlpxEngine=$2
		_dlpxEnvName=$3
		export ORACLE_BASE=$4
		;;
	3)	_newOraHome=$1
		_dlpxEngine=$2
		_dlpxEnvName=$3
		;;
	*)	echo "Usage: \"upgrd.sh <new-ORACLE_HOME> <dlpx-Engine> <dlpx-EnvName> [ <ORACLE_BASE> ]\"; aborting..."
		echo "        <new-ORACLE_HOME> to which this VDB is being upgraded"
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
# Verify how the upgrade is going to be performed...
#--------------------------------------------------------------------------------
echo ""
echo "upgrading ORACLE_SID \"${ORACLE_SID}\""
echo "from ORACLE_BASE \"${ORACLE_BASE}\", ORACLE_HOME \"${ORACLE_HOME}\", LD_LIBRARY_PATH \"${LD_LIBRARY_PATH}\""
echo "to ORACLE_HOME \"${_newOraHome}\""
echo ""
#
#--------------------------------------------------------------------------------
# Save a copy of the Oracle initialization parameter file to "/tmp"...
#--------------------------------------------------------------------------------
if [ -f ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora ]
then
	cp ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora /tmp
	if (( $? != 0 ))
	then
		echo "copy of init${ORACLE_SID}.ora from \"${ORACLE_HOME}/dbs\" to \"/tmp\" failed; aborting..."
		exit 1
	fi
fi
if [ -f ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora ]
then
	cp ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora /tmp
	if (( $? != 0 ))
	then
		echo "copy of spfile${ORACLE_SID}.ora from \"${ORACLE_HOME}/dbs\" to \"/tmp\" failed; aborting..."
		exit 1
	fi
fi
#
#--------------------------------------------------------------------------------
# If the SQL script "emremove.sql" exists in the new Oracle version's ORACLE_HOME,
# then run it to remove the Enterprise Manager schema...
#--------------------------------------------------------------------------------
if [ -f ${_newOraHome}/rdbms/admin/emremove.sql ]
then
	sqlplus / as sysdba << __EOF__
whenever oserror exit failure
start ${_newOraHome}/rdbms/admin/emremove.sql
exit success
__EOF__
	if (( $? != 0 ))
	then
		echo "Running \"${_newOraHome}/rdbms/admin/emremove.sql\" failed; aborting..."
		exit 1
	fi
fi
#
#--------------------------------------------------------------------------------
# Save "old" settings of ORACLE_HOME and ORACLE_BASE and set "new" settings for
# ORACLE_HOME and PATH to the upgraded version...
#--------------------------------------------------------------------------------
_oldOraBase=${ORACLE_BASE}
_oldOraHome=${ORACLE_HOME}
export ORACLE_HOME=${_newOraHome}
export PATH=${ORACLE_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
#
#--------------------------------------------------------------------------------
# Copy saved-off copy of the Oracle initialization parameter file to the
# "dbs" subdirectory within the new ORACLE_HOME...
#--------------------------------------------------------------------------------
if [ -f /tmp/init${ORACLE_SID}.ora ]
then
	cp /tmp/init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs
	if (( $? != 0 ))
	then
		echo "copy of init${ORACLE_SID}.ora from \"/tmp\" to \"${ORACLE_HOME}/dbs\" failed; aborting..."
		exit 1
	fi
fi
if [ -f /tmp/spfile${ORACLE_SID}.ora ]
then
	cp /tmp/spfile${ORACLE_SID}.ora ${ORACLE_HOME}/dbs
	if (( $? != 0 ))
	then
		echo "copy of spfile${ORACLE_SID}.ora from \"/tmp\" to \"${ORACLE_HOME}/dbs\" failed; aborting..."
		exit 1
	fi
fi
#
#--------------------------------------------------------------------------------
# Call the Oracle DBUA utility to perform the database upgrade...
#--------------------------------------------------------------------------------
${ORACLE_HOME}/bin/dbua	\
	-silent \
	-sid ${ORACLE_SID} \
	-oracleHome ${_oldOraHome} \
	-oracleBase ${_oldOraBase} \
	-autoextendFiles \
	-recompile_invalid_objects true \
	-degree_of_parallelism 4
if (( $? != 0 ))
then
	echo "DBUA failed; aborting..."
	exit 1
fi
echo "silent DBUA completed successfully"
#
#--------------------------------------------------------------------------------
# Connect into the CLI of the Delphix Engine and finish the upgrade...
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
echo "Upgrade completed successfully"
exit 0
