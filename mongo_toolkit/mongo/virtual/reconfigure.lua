--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--

-- snapshotJson passed to configure and reconfigure
env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="reconfigure",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_SNAPSHOT_METADATA=snapshotJson,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword
}

provisionInfo = RunBash{
   command     = resources["provision.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env,
   outputSchema = {
      type = "object",
      additionalProperties = false,
      properties = {
         dbPath = { type="string" },
         mongoPort = { type="integer" },
         prettyName = { type="string" }
      }
  }
}

RunBash{
   command     = resources["start.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env
}

-- RunBash{
--   command     = resources["initiate.sh"],
--   environment = source.environment,
--   user        = source.environmentUser,
--   host        = source.host,
--   variables   = env
-- }

return provisionInfo