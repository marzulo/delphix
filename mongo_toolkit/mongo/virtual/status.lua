--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--
-- virtual/status.lua
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="status",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_STATUS_TYPE="virtual"
}

return RunBash {
  command      = resources['status.sh'],
  environment  = source.environment,
  user         = source.environmentUser,
  host         = source.host,
  variables    = env,
  outputSchema = { type = 'string' }
}
