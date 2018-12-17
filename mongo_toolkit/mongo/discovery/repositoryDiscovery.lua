--
-- Copyright (c) 2015 by Delphix. All rights reserved.
--
env = {
   DLPX_TOOLKIT_WORKFLOW="repositoryDiscovery",
   DLPX_LIBRARY_SOURCE=resources["library.sh"]
}

return RunBash {
  command = resources["repoDiscovery.sh"],
  environment = remote.environment,
  user = remote.environmentUser,
  host = remote.host,
  variables = env,
  outputSchema = {
    type = "array",
    items = {
      type="object",
      additionalProperties = false,
      properties = {
        mongoInstallPath  = { type="string" },
        mongoShellPath  = { type="string" },
        version      = { type="string" },
        prettyName   = { type="string" }
      }
    }
  }
}
