# Module to create a database and user in a PostgreSQL RDS instance

This module creates the following resources, to work with the Smile CDR Helm Chart

Per DB:

* Secrets Manager Secret for user/db
    * Uses passed in KMS key
    * Randomly generated secret
* Thing
