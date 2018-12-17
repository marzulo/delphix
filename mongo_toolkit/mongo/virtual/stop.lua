--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--

env = {
   DLPX_DATA_DIRECTORY=source.dataDirectory,
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   DLPX_TOOLKIT_WORKFLOW="stop",
   MONGO_BIND_IP=parameters.bindIP,
   MONGO_PORT=parameters.mongoPort,
   MONGO_USER_NAME=parameters.mongoUserName,
   MONGO_USER_PASSWORD=parameters.mongoPassword
}

delphixOwned = RunBash{
   command     = resources["checkOwnership.sh"],
   environment = source.environment,
   user        = source.environmentUser,
   host        = source.host,
   variables   = env,
   outputSchema = { type = 'boolean' }
}

if delphixOwned then

	RunBash{
   		command     = resources["shutdown.sh"],
   		environment = source.environment,
   		user        = source.environmentUser,
   		host        = source.host,
   		variables   = env
	}

end