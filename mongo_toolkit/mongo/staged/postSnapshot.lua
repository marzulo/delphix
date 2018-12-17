--
-- Copyright (c) 2015, 2016 by Delphix. All rights reserved.
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="postSnapshot",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_KEYFILE_PATH=parameters.keyfilePath,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_REPLICASET=config.replicaSet,
   MONGO_STANDBY_HOST=parameters.standbyHost,
   MONGO_STORAGE_ENGINE=parameters.storageEngine,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword
}

RunBash{
   command     = resources["addStagingToPrimary.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env
}

return RunBash {
  command     = resources["recordStatus.sh"],
  environment = source.stagingEnvironment,
  user        = source.stagingEnvironmentUser,
  host        = source.stagingHost,
  variables   = env,
  outputSchema = {
    type = "object",
    additionalProperties = false,
    properties = {
      toolkitVersion = { type="string" },
      timestamp      = { type="string" },
      architecture   = { type="string" },
      osType         = { type="string" },
      osVersion      = { type="string" },
      mongoVersion   = { type="string" },
      delphixMount   = { type="string" },
      mongoPort      = { type="integer" },
      storageEngine  = { type="string" },
      mongoAuth      = { type="string" },
      replicaSet     = { type="string" },
      journalInterval = { type="integer" },
      oplogSize      = { type="integer" }
   }
  }
}