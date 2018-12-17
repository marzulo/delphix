--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="postSnapshot",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_STAGING_SERVER_BOOL=false,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword
}

return RunBash{
   command     = resources["recordStatus.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env,
   outputSchema = {
      type = "object",
      additionalProperties = false,
      properties = {
         toolkitVersion = { type="string" },
         timestamp = { type="string" },
         architecture = { type="string" },
         osType = { type="string" },
         osVersion = { type="string" },
         mongoVersion = { type="string" },
         delphixMount = { type="string" },
         mongoPort = { type="integer" },
         storageEngine = { type="string" },
         mongoAuth = { type="string" },
         replicaSet = { type="string" },
         journalInterval = { type="integer" },
         oplogSize = { type="integer" }
      }
   }
}