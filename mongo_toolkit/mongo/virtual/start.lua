--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="start",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_JOURNAL_FLUSH=parameters.journalInterval,
   MONGO_OPLOG_SIZE=parameters.oplogSize,
   MONGO_PORT=parameters.mongoPort,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword
}

RunBash{
   command     = resources["start.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env
}