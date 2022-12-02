# Multiple Database Support #

In order to support multiple databases you must configure them in the database section, either under the Crunchy subsection or the external subsection.

## Configuring Databases with CrunchyData PGO ##

When using CrunchyData PGO, you specify the username used for each DB, as the PGO automatically creates a secret based on the username.
These secrets contain all required connection details, which are automatically referenced, so it's all that's needed in the configuration.
When you specify usernames like this, and internal provisioning is enabled, the `PostgresCluster` resource will automatically create a new DB per user, each with the `-db` suffix.

## Configuring External Databases ##

When using external databases, it's similar in concept to the above, except you must directly reference the secret name as we can make no assumptions on the secret name, like we can with the CrunchyData PGO.
We also, cannot be sure which keys in the secret contain which credential details, so you can specify key names if required.
Finally, we cannot be sure that all details are provided in the secrets, so you can provide value overrides. Note, you may not override the password. Nuh-uh! Sneaky!

## Connecting DB to modules ##

In either of the above cases, when you define a DB, you also tell it which module will be using it. By doing this, it will automatically create environment variables in the form of `MODULENAME_DB_DETAIL`. For example, configuring a DB for the `clustermgr` module, it will create `CLUSTERMGR_DB_URL` for example.
When the module definition references `DB_URL`, this will be automatically mutated to `CLUSTERMGR_DB_URL` for any module that consumes DB variables.
