--
-- Copyright (c) 2015, 2016 by Delphix. All rights reserved.
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="resync",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_KEYFILE_PATH=parameters.keyfilePath,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_REPLICASET=config.replicaSet,
   MONGO_STANDBY_HOST=parameters.standbyHost,
   MONGO_STORAGE_ENGINE=parameters.storageEngine,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword,
   VDB_GUID=source.guid
}

--
-- Place a stub in the data directory so we can later verify whether Delphix created this instance
--

RunBash{
   command     = resources["addStagingToPrimary.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env
}

RunBash{
   command     = resources["startStaging.sh"],
   environment = source.stagingEnvironment,
   user        = source.stagingEnvironmentUser,
   host        = source.stagingHost,
   variables   = env
}