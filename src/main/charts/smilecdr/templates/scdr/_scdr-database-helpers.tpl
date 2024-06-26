{{/*
Define Smile CDR DB Environment
Environment variables for databases
*/}}
{{- define "smilecdr.dbEnvVars" -}}
  {{- $envVars := list -}}
  {{- if eq .Values.database.crunchypgo.enabled .Values.database.external.enabled -}}
    {{- /* You must configure exactly one of crunchypgo or external database.
        This check is skipped for unit testing. */ -}}
    {{- if not .Values.unitTesting -}}
      {{- fail "You must either configure an external database (`database.external.enabled: true`) or crunchypgo (`database.crunchypgo.enabled: true`)" -}}
    {{- end -}}
  {{- end -}}

  {{- if .Values.database.crunchypgo.enabled -}}
    {{- $crunchyReleaseName := default (printf "%s-pg" .Release.Name) .Values.database.crunchypgo.releaseName -}}
    {{- /*
    Define env vars from crunchy secrets.
    Include them from lists defined in .Values.database.crunchypgo.users
    Will not over-complicate with the empty list case, as we will define defaults in values file.
    */ -}}
    {{- range $v := .Values.database.crunchypgo.users -}}
      {{- /* It's possible to define databases that are not in use by Smile CDR, so we don't want to
      define the environment variables by default. Only if the `module` is set. */ -}}
      {{- if $v.module -}}
        {{- $username := $v.name -}}
        {{- $module := $v.module -}}

        {{- $envPrefix := printf "%s_" ( upper $module ) -}}
        {{- /* If there is only a single DB, don't use an environment variable prefix as
            the same environment variables will be shared amongst all modules.
            */ -}}
        {{- $numCrunchyUsersWithModules := 0 -}}
        {{- range $crunchyUser := $.Values.database.crunchypgo.users -}}
          {{- if hasKey $crunchyUser "module" -}}
            {{- $numCrunchyUsersWithModules = add $numCrunchyUsersWithModules 1 -}}
          {{- end -}}
        {{- end -}}
        {{- if le $numCrunchyUsersWithModules 1 -}}
          {{- $envPrefix = "" -}}
        {{- end -}}

        {{- $secretName := printf "%s-pguser-%s" $crunchyReleaseName $username -}}
        {{- $secretKeyRef := dict "name" $secretName -}}
        {{- $pgBouncerPrefix := (ternary "pgbouncer-" "" (hasKey $.Values.database.crunchypgo.config "pgBouncerConfig")) -}}
        {{- $keyMap := dict -}}

        {{- /* TODO: refactor using "smilecdr.database.external.requiredEnvVars" */ -}}
        {{- /* Define and add DB_URL */ -}}
        {{- $env := dict "name" (printf "%sDB_URL" $envPrefix) -}}
        {{- $keyMap = dict "key" (printf "%shost" $pgBouncerPrefix) -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- $envVars = append $envVars $env -}}

        {{- /* Define and add DB_PORT */ -}}
        {{- $env := dict "name" (printf "%sDB_PORT" $envPrefix) -}}
        {{- $keyMap = dict "key" (printf "%sport" $pgBouncerPrefix) -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- $envVars = append $envVars $env -}}

        {{- /* Define and add DB_DATABASE */ -}}
        {{- $env := dict "name" (printf "%sDB_DATABASE" $envPrefix) -}}
        {{- $keyMap = dict "key" "dbname" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- $envVars = append $envVars $env -}}

        {{- /* Define and add DB_USER */ -}}
        {{- $env := dict "name" (printf "%sDB_USER" $envPrefix) -}}
        {{- $keyMap = dict "key" "user" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- $envVars = append $envVars $env -}}

        {{- /* Define and add DB_PASS */ -}}
        {{- $env := dict "name" (printf "%sDB_PASS" $envPrefix) -}}
        {{- $keyMap = dict "key" "password" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- $envVars = append $envVars $env -}}
      {{- end -}}
    {{- end -}}
    {{- /* If there are no env vars, then something is misconfigured. */ -}}
    {{- if lt (len $envVars) 1 -}}
      {{- fail "Something went wrong with Crunchy PGO Database configuration. `$envVars` is empty and should not be! (E456)" -}}
    {{- end -}}
  {{- else if .Values.database.external.enabled -}}
    {{- /* Get the canonical list of external DB connections */ -}}
    {{- $dbConnections := (include "smilecdr.database.external.connections" .) | fromYamlArray -}}
    {{- /* For each DB connection, generate the env vars required for it. */ -}}
    {{- /* If it is configured for multiple modules, create the env vars
        for each one. */ -}}
    {{- range $theConnectionSpec := $dbConnections -}}

      {{- /* TODO: CHECK-HUH? Check to see if supported credentials type is being used */ -}}
      {{- /* range $theSecret := .Values.database.external.databases */ -}}
      {{- /* $secretName := $theConnectionSpec.secretName */ -}}
      {{- /* If there is no modules key, or if it's empty, or if there is only 1 dbConnection spec, then keep the prefix
          empty and do not cycle through the modules for the connection. We will used `DB_*` which will be shared by all
          modules. */ -}}
      {{- /* if or (not (hasKey $theConnectionSpec "modules")) (lt (len $theConnectionSpec.modules) 1) (lt (len $dbConnections) 2) */ -}}
      {{- range $moduleName := $theConnectionSpec.modules -}}
        {{- $envPrefix := "" -}}
        {{- /*
        If there is only a single DB, don't use a prefix as the same
        environment variables will be shared amongst all modules
        If there is more than 1 db connection, then multiple DBs are implied no mattwer how many modules each one is used for.
        If there is only 1 db connection, then multiple DBs are only implied if it's used for multiple modules.
        */ -}}
        {{- if or (gt (len $dbConnections) 1) (gt (len $theConnectionSpec.modules) 1) -}}
          {{- $envPrefix = printf "%s_" ( upper $moduleName ) -}}
        {{- end -}}

        {{- /* fail (printf "$theConnectionSpec: %s" (toPrettyJson $theConnectionSpec)) */ -}}
        {{- if $theConnectionSpec.envMap -}}
          {{- /* fail (printf "$theConnectionSpec.envMap: %s" (toPrettyJson $theConnectionSpec.envMap)) */ -}}
          {{- range $theEnvName, $theEnvSpec := $theConnectionSpec.envMap -}}
            {{- $env := dict "name" (printf "%s%s" $envPrefix $theEnvSpec.envVarName) -}}
            {{- if $theEnvSpec.value -}}
              {{- /* Using a hard coded value */ -}}
              {{- $_ := set $env "value" $theEnvSpec.value -}}
            {{- else -}}
              {{- /* Using a secret (implied) */ -}}
              {{- /* Maybe assert on this. If we specify secret for this env var, it HAS to exist. */ -}}

              {{- $theSecret := $theConnectionSpec.secret -}}
              {{- /* fail (printf "$theConnectionSpecc: %s" (toPrettyJson $theConnectionSpec)) */ -}}
              {{- $secretResourceName := (lower $theSecret.secretName) -}}
              {{- /* Get the keyMap from the secret */ -}}
              {{- if eq $theEnvName "passworddd" -}}
                {{- fail (printf "$moduleName: %s\n$theEnvName: %s\n$theEnvSpec: %s" $moduleName $theEnvName (toPrettyJson $theEnvSpec)) -}}

              {{- end -}}
              {{- $theKeySpec := get $theSecret.secretKeyMap $theEnvSpec.secretKeyName -}}
              {{- $secretKeyRef := dict "name" $secretResourceName -}}
              {{- $k8sSecretKeyName := ternary $theEnvSpec.k8sSecretKeyName $theEnvSpec.secretKeyName (hasKey $theEnvSpec "k8sSecretKeyName") -}}
              {{- $_ := set $secretKeyRef "key" $k8sSecretKeyName -}}
              {{- $_ := set $env "valueFrom" (dict "secretKeyRef" $secretKeyRef) -}}
            {{- end -}}

            {{- $envVars = append $envVars $env -}}
          {{- end -}}
        {{- end -}}

      {{- end -}}
      {{- /* If there are no env vars, then something is misconfigured. */ -}}
      {{- if and (lt (len $envVars) 1) (ne $theConnectionSpec.connectionConfig.authentication.type "secretsmanager") -}}
        {{- fail (printf "$envVars: %s" (toPrettyJson $theConnectionSpec.envMap)) -}}
        {{- fail "Something went wrong with External Database configuration. `$envVars` is empty and should not be! (E457)" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}

{{- /* Canonical list of external database secrets for a given node
This returns a verified canonical list of objects that define database connection configuration secrets
*/ -}}
{{- define "smilecdr.database.external.secrets" -}}
  {{- $extDBSecrets := list -}}
  {{- $dbConnections := (include "smilecdr.database.external.connections" .) | fromYamlArray -}}
  {{- range $theDBConnectionSpec := $dbConnections -}}
    {{- /* If the DB connection requires a secret (either for auth+connection info, or just for connection info)
        then add it to the list. */ -}}
    {{- if $theDBConnectionSpec.secret -}}
      {{- $extDBSecrets = append $extDBSecrets $theDBConnectionSpec.secret -}}
    {{- end -}}
    {{- /* if contains $theDBConnectionSpec.connectionConfigSource.source "sscsi k8sSecret" -}}
      {{- $extDBSecrets = append $extDBSecrets (deepCopy $theDBConnectionSpec.connectionConfigSource) -}}
    {{- end */ -}}
  {{- end -}}
  {{- $extDBSecrets | toYaml -}}
{{- end -}}

{{- /*
Canonical list of external database connection configurations for a given node
This returns a verified canonical list of objects that define database connection configuration as so:
```
{
  connectionConfigSource: - `dict` of configuration source (i.e. secrets, etc)
  connectionConfig: - `dict` of generated configuration for db connection
  modules: - `list` of modules that use this connection
}
```
*/ -}}
{{- define "smilecdr.database.external.connections" -}}
  {{- $rootCTX := . -}}
  {{- $nodeSpec := .Values -}}
  {{- $legacyMode := false -}}
  {{- $dbConnections := list -}}
  {{- if $nodeSpec.database.external.enabled -}}
    {{- /* Determine if configuration is using the deprecated method of specifying DB connection credentials.
        Easily determined as the entry in `databases` will use `secretName`. */ -}}
    {{- range $dbConfig := $nodeSpec.database.external.databases -}}
      {{- if hasKey $dbConfig "secretName" -}}
        {{- $legacyMode = true -}}
      {{- end -}}
    {{- end -}}

    {{- $requiredEnvVars := include "smilecdr.database.external.requiredEnvVars" . | fromYamlArray -}}

    {{- /* *****************************************************
            New secrets mechanism with IAM/SecretsManager support)
            Includes support for deprecated legacy mechanisms (To be removed later)
            ***************************************************** */ -}}
    {{- $defaultConnectionConfigSource := dict -}}
    {{- $defaultConnectionConfig := dict "authentication" (dict "type" "pass") -}}
    {{- $defaults := deepCopy (mergeOverwrite (dict "connectionConfigSource" $defaultConnectionConfigSource "connectionConfig" $defaultConnectionConfig) $nodeSpec.database.external.defaults) -}}

    {{- if $legacyMode -}}
      {{- /* If using legacy mode, we will take the .credentials to override the defaults */ -}}
      {{- $credentialsType := default "k8sSecret" (($nodeSpec.database.external.credentials).type) -}}
      {{- $credentialsProvider := ($nodeSpec.database.external.credentials).provider -}}

      {{- if contains $credentialsType "sscsi k8sSecret" -}}
        {{- $_ := set $defaults.connectionConfigSource "source" $credentialsType -}}
        {{- $_ := set $defaults.connectionConfigSource "provider" $credentialsProvider -}}
      {{- else -}}
        {{- fail (printf "Secrets of type `%s` are not supported. Please use `sscsi` or `k8sSecret`" $credentialsType) -}}
      {{- end -}}
    {{- end -}}

    {{- range $theDBConnectionSpec := $nodeSpec.database.external.databases -}}

      {{- if $legacyMode -}}
        {{- /* Rework the connection config to work with the new mechanism. */ -}}
        {{- $legacyConnectionSpec := deepCopy $theDBConnectionSpec -}}
        {{- /* Copy all the legacy 'root' elements into 'connectionConfig'. This is for direct values and key overrides. */ -}}
        {{- $theDBConnectionSpec = dict -}}
        {{- $_ := set $theDBConnectionSpec "name" (printf "legacy-%s" $legacyConnectionSpec.module) -}}
        {{- $_ := set $theDBConnectionSpec "modules" (list $legacyConnectionSpec.module ) -}}
        {{- $connectionConfigSource := dict "secretName" $legacyConnectionSpec.secretName -}}
        {{- if $legacyConnectionSpec.secretArn -}}
          {{- $_ := set $connectionConfigSource "secretArn" $legacyConnectionSpec.secretArn -}}
        {{- end -}}

        {{- $_ := set $theDBConnectionSpec "connectionConfigSource" $connectionConfigSource -}}
        {{- $_ := set $theDBConnectionSpec "connectionConfig" (omit $legacyConnectionSpec "module" "secretName" "secretArn") -}}
        {{- /* Also copy these into 'keyMappings' */ -}}
        {{- $_ := set $theDBConnectionSpec.connectionConfigSource "secretKeyMappings" (omit $legacyConnectionSpec "module" "secretName" "secretArn") -}}
      {{- end -}}

      {{- $_ := required "You must specify `name` for external DB connection configurations. (E123)" $theDBConnectionSpec.name -}}

      {{- /* Merge db connection defaults */ -}}
      {{- $theDBConnectionSpec = mergeOverwrite (deepCopy $defaults) $theDBConnectionSpec -}}

      {{- /* TODO: This condition should never be invoked because "connectionConfigSource" is included up above */ -}}
      {{- if or (not (hasKey $theDBConnectionSpec "connectionConfigSource")) (not (hasKey $theDBConnectionSpec.connectionConfigSource "source")) -}}
        {{- fail (printf "You must either provide `connectionConfigSource.source` for your DB configuration or provide a default.") -}}
      {{- end -}}
      {{- if not (contains $theDBConnectionSpec.connectionConfigSource.source "sscsi k8sSecret none") -}}
        {{- fail (printf "DB connection config source of `%s` is not supported. Please use `sscsi`, `k8sSecret` or `none`." $theDBConnectionSpec.connectionConfigSource.source) -}}
      {{- end -}}

      {{- /* Secrets Handling */ -}}
      {{- /*
          For the database secrets will be used in multiple situations...
          * Connection details and auth credentials
          * Connection details only (i.e if using RDS IAM or Secrets Manager auth)

          As we call it 'connection config' rather than just 'secret' or 'credentials', it can be tricly to follow.
          */ -}}

      {{- /* In this scenario, a secret IS being used, so we can use the secretConfig template to validate, parse and provide required secret configuration. */ -}}
      {{- $secretSpec := dict -}}
      {{- $secretSpec = omit $theDBConnectionSpec.connectionConfigSource "source" -}}

      {{- $_ := set $secretSpec "type" $theDBConnectionSpec.connectionConfigSource.source -}}

      {{- /* Determine if secret and keyMapping is being used */ -}}
      {{- $usingSecret := contains (lower $secretSpec.type) "sscsi k8ssecret" -}}
      {{- $usingKeyMappings := and $usingSecret (hasKey $secretSpec "secretKeyMappings") -}}

      {{- /* If the provided DB configuration includes any allowed key overrides, then they get sanitized and included here */ -}}
      {{- $secretKeyMappings := dict -}}
      {{- $envMaps := dict -}}

      {{- range $theRequiredEnvVarSpec := $requiredEnvVars -}}
        {{- /* We want to attempt to set each required env var once, so this is the outer loop */ -}}

        {{- $mapSensitiveValues := true -}}
        {{- if contains $theDBConnectionSpec.connectionConfig.authentication.type "iam secretsmanager" -}}
          {{- $mapSensitiveValues = false -}}
        {{- end -}}

        {{- $envMap := dict -}}

        {{- /* Default key mapping values from $requiredEnvVars */ -}}
        {{- $keyMapping := dict -}}
        {{- $_ := set $keyMapping "secretKeyName" $theRequiredEnvVarSpec.defaultKey -}}
        {{- $_ := set $keyMapping "defaultKeyName" $theRequiredEnvVarSpec.defaultKey -}}

        {{- /* Determine if the env var should be added or not. */ -}}
        {{- $createEnvVar := false -}}
        {{- /* Only add env var if it's defined in requiredEnvVars */ -}}
        {{- if $theRequiredEnvVarSpec.envVarName -}}
          {{- /* For env vars with secret material, only add if mapSensitiveValues set. */ -}}
          {{- if $theRequiredEnvVarSpec.secretMaterial -}}
            {{- if $mapSensitiveValues -}}
              {{- $createEnvVar = true -}}
            {{- else -}}
              {{- $createEnvVar = false -}}
            {{- end -}}
          {{- else -}}
            {{- $createEnvVar = true -}}
          {{- end -}}
        {{- end -}}

        {{- /* Determine and add the env var if enabled */ -}}
        {{- if $createEnvVar -}}
          {{- $_ := set $envMap "name" $theRequiredEnvVarSpec.name -}}
          {{- $envVarName := $theRequiredEnvVarSpec.envVarName -}}
          {{- $_ := set $envMap "envVarName" $envVarName -}}
          {{- /* Iterate through allowed keys. We are checking for the following:
              * Does the secretSpec have a key such as 'urlKey'. This is a key mapping override
              * Does the secretSpec have a key such as 'url'. This is a direct value override
              * If it has neither, use the default key mapping
              */ -}}
          {{- $keyFound := false -}}

          {{- range $theAllowedKeyName := splitList " " $theRequiredEnvVarSpec.allowedKeys -}}

            {{- /* $theAllowedOverrideKeyName is the name of an allowed key mapping override, e.g. 'urlKey' */ -}}
            {{- $theAllowedOverrideKeyName := (printf "%sKey" $theAllowedKeyName) -}}

            {{- /* Only check for secret key overrides if a secretKeyMapping is being used */ -}}
            {{- if and $usingKeyMappings (hasKey $secretSpec.secretKeyMappings $theAllowedOverrideKeyName) -}}
              {{- /* The provided secretSpec has the allowed override key name inside 'secretKeyMappings'
                  Add the key name to the keyMaps AND the envMap... */ -}}
              {{- $_ := set $keyMapping "secretKeyName" (get $secretSpec.secretKeyMappings $theAllowedOverrideKeyName) -}}
              {{- $_ := set $envMap "secretKeyName" (get $secretSpec.secretKeyMappings $theAllowedOverrideKeyName) -}}
              {{- $keyFound = true -}}

            {{- else if (hasKey $theDBConnectionSpec.connectionConfig $theAllowedKeyName) -}}
              {{- /* The provided secretSpec has an allowed direct override key
                  Add to the value envMaps but NOT to the keyMap */ -}}
              {{- /* Add the envMap to the envMaps */ -}}
              {{- $_ := set $envMap "value" (toString (get $theDBConnectionSpec.connectionConfig $theAllowedKeyName)) -}}

              {{- $keyFound = true -}}
            {{- end -}}
          {{- end -}}

          {{- /* Check if a key override or direct value override was found. If not, use the default key */ -}}
          {{- if not $keyFound -}}
            {{- /* Finally, use the default secret key name.
                In other words, we add the key name to the keyMaps AND the envMap...
                */ -}}

            {{- $_ := set $keyMapping "secretKeyName" $theRequiredEnvVarSpec.defaultKey -}}
            {{- $_ := set $envMap "secretKeyName" $theRequiredEnvVarSpec.defaultKey -}}
          {{- end -}}

          {{- $_ := set $secretKeyMappings $theRequiredEnvVarSpec.name $keyMapping -}}
          {{- $_ := set $envMaps $theRequiredEnvVarSpec.name $envMap -}}

        {{- end -}}
      {{- end -}}

      {{- /* If a secret is being used, parse it and add the final config to connection object */ -}}
      {{- if $usingSecret -}}
        {{- $_ := set $secretSpec "secretKeyMap" $secretKeyMappings -}}
        {{- $_ := set $secretSpec "objectAliasExtraSuffix" "db" -}}
        {{- $_ := set $secretSpec "syncSecret" true -}}
        {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $rootCTX "secretSpec" $secretSpec) | fromYaml -}}
        {{- $_ := set $theDBConnectionSpec "secret" $secretConfig -}}
      {{- end -}}

      {{- /* Add env maps to the connection object */ -}}
      {{- $_ := set $theDBConnectionSpec "envMap" $envMaps -}}

      {{- /* Some extra processing for IAM & Secrets Manager */ -}}
      {{- if eq $theDBConnectionSpec.connectionConfig.authentication.type "iam" -}}
        {{- $_ := set $theDBConnectionSpec.connectionConfig.authentication "iamProvider" (required "You must specify a provider when using IAM for DB authentication" $theDBConnectionSpec.connectionConfig.authentication.provider) -}}
        {{- $_ := set $theDBConnectionSpec.connectionConfig.authentication "iamTokenLifetimeMillis" (default 900000 $theDBConnectionSpec.connectionConfig.authentication.iamTokenLifetimeMillis) -}}
      {{- end -}}
      {{- if eq $theDBConnectionSpec.connectionConfig.authentication.type "secretsmanager" -}}
        {{- $_ := set $theDBConnectionSpec.connectionConfig.authentication "secretsManagerProvider" (required "You must specify a provider when using `secretsmanager` for DB authentication" $theDBConnectionSpec.connectionConfig.authentication.provider) -}}
        {{- if not (hasKey $theDBConnectionSpec.connectionConfig.authentication "secretArn") -}}
          {{- $_ := set $theDBConnectionSpec.connectionConfig.authentication "secretArn" (required "You must specify `connectionConfig.secretArn` or `connectionConfigSource.secretArn` when using `secretsmanager` for DB authentication" $theDBConnectionSpec.connectionConfigSource.secretArn) -}}
        {{- end -}}
      {{- end -}}

      {{- $dbConnections = append $dbConnections $theDBConnectionSpec -}}
    {{- end -}}
    {{- if eq (len $dbConnections) 0 -}}
      {{- /* If using external database, you must define some database connections.
          This check is skipped for unit testing. */ -}}
      {{- if not .Values.unitTesting -}}
        {{- fail (printf "You must configure and enable database credential configurations when using external databases. (E156)") -}}
      {{- end -}}
    {{- end -}}

  {{- end -}}
  {{- $dbConnections | toYaml -}}
{{- end -}}

{{- /*
    Defines required env vars for database connections, along with the default/allowed configuration
    mappings.
    Secrets are marked accordingly so that they cannot be included directly in configurations, but still
    need to be configured when using secrets, as opposed to IAM.
    */ -}}
{{- define "smilecdr.database.external.requiredEnvVars" -}}
  {{- $defaultSecretKeyMappings := list -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "host" "envVarName" "DB_URL" "allowedKeys" "url host" "defaultKey" "host" ) -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "port" "envVarName" "DB_PORT" "allowedKeys" "port" "defaultKey" "port") -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "dbname" "envVarName" "DB_DATABASE" "allowedKeys" "dbname dbName" "defaultKey" "dbname") -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "user" "envVarName" "DB_USER" "allowedKeys" "user username userName" "defaultKey" "username") -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "engine" "allowedKeys" "engine" "defaultKey" "engine") -}}
  {{- $defaultSecretKeyMappings = append $defaultSecretKeyMappings (dict "name" "password" "envVarName" "DB_PASS" "allowedKeys" "pass pwd password" "defaultKey" "password" "secretMaterial" true) -}}
  {{- $defaultSecretKeyMappings | toYaml -}}
{{- end -}}
