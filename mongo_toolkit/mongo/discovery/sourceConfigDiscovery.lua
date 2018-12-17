--
-- Copyright (c) 2016 by Delphix. All rights reserved.
--
env = {
   DLPX_TOOLKIT_WORKFLOW="sourceConfigDiscovery",
   DLPX_LIBRARY_SOURCE=resources["library.sh"],
   MONGO_VERSION = repository.version,
   MONGO_INSTALL_PATH = repository.mongoInstallPath
}

return RunBash {
  command = resources["sourceConfigDiscovery.sh"],
  environment = remote.environment,
  user = remote.environmentUser,
  host = remote.host,
  variables = env,
  outputSchema = {
    type = "array",
    items = {
      type = "object",
      additionalProperties = false,
      properties = {
        prettyName = { type="string" },
        dbPath = { type="string" },
        mongoPort = { type="integer" },
        replicaSet = { type="string" },
        keyfilePath = { type="string" }
      }
    }
  }
}