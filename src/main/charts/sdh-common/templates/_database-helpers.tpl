{{/*
Define DB Environment
*/}}
{{- define "sdhCommon.dbEnvVars" -}}
  {{- $envVars := list -}}
  {{- if and ((.Values.database).crunchypgo).enabled ((.Values.database).external).enabled -}}
    {{- fail "You have enabled Crunchy PGO and external databases. You can only select one." -}}
  {{- end -}}
  {{- if ((.Values.database).crunchypgo).enabled -}}
    {{- $crunchyReleaseName := default (printf "%s-pg" .Release.Name) .Values.database.crunchypgo.releaseName -}}
    {{- /*
    Define env vars from crunchy secrets.
    Include them from lists defined in .Values.database.crunchypgo.users
    Will not over-complicate with the empty list case, as we will define defaults in values file.
    */ -}}

    {{- /* Different logic depending on whether or not module is defined */ -}}
    {{- /* If module is defined, it is a Smile CDR database.
        We will prepend the suffix as long as there is more than one DB with module
        Otherwise it is NOT a Smile CDR database. No prefix will be included.
        In the case that there are databases with module assignments, we will ONLY
        render those out as env Variables.
        In the case that there are none, any db definitions are for some other chart
        so they will ne rendered.
    */ -}}

    {{- /* Build list of database definitions with & without module definitions */ -}}
    {{- $dbDefsWithModule := list -}}
    {{- $dbDefsWithoutModule := list -}}
    {{- range $v := .Values.database.crunchypgo.users -}}
      {{- /* Deprecating `module` to use more descriptive `cdrModule`.
             Support both for now. Newer `cdrModule` takes priority if
             both are defined for some reason. */ -}}
      {{- if (hasKey $v "cdrModule") -}}
        {{- $dbDefsWithModule = append $dbDefsWithModule $v -}}
      {{- else if (hasKey $v "module") -}}
        {{- $_ := set $v "cdrModule" $v.module -}}
        {{- $_ := unset $v "module" -}}
        {{- $dbDefsWithModule = append $dbDefsWithModule $v -}}
      {{- else -}}
        {{- $dbDefsWithoutModule = append $dbDefsWithoutModule $v -}}
      {{- end -}}
    {{- end -}}

    {{- /* If there are definitions with modules, only render them */ -}}
    {{- $dbDefsToUse := list -}}
    {{- if gt (len $dbDefsWithModule) 0 -}}
      {{- $dbDefsToUse = concat $dbDefsToUse $dbDefsWithModule -}}
    {{- else if gt (len $dbDefsWithoutModule) 0 -}}
      {{- $dbDefsToUse = concat $dbDefsToUse $dbDefsWithoutModule -}}
    {{- end -}}

    {{- range $v := $dbDefsToUse -}}
      {{- $username := $v.name -}}
      {{- $envPrefix := "" -}}
      {{- if (hasKey $v "cdrModule") -}}
        {{- /*
        Only set env prefix if there is more than one db with cdrModule defined.
        We don't use a prefix if there is only one, as the same environment
        variables will be shared amongst all modules.
        We do this with the size of the parent array as it should only contain
        db defs with modules.
        */ -}}
        {{- if gt (len $dbDefsToUse) 1 -}}
          {{- $envPrefix = printf "%s_" ( upper $v.cdrModule ) -}}
        {{- end -}}
      {{- end -}}

      {{- $secretName := printf "%s-pguser-%s" $crunchyReleaseName $username -}}
      {{- $secretKeyRef := dict "name" $secretName -}}
      {{- $pgBouncerPrefix := (ternary "pgbouncer-" "" (and (hasKey $.Values.database.crunchypgo "config") (hasKey $.Values.database.crunchypgo.config "pgBouncerConfig"))) -}}
      {{- $keyMap := dict -}}

      {{- /* Define and add DB_TYPE -}}
      {{- $varName := default "DB_TYPE" (($.Values.database).envVarNames).dbtype -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" (printf "%sdbtype" $pgBouncerPrefix) -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env */ -}}

      {{- /* Define and add DB_URL */ -}}
      {{- $varName := default "DB_URL" (($.Values.database).envVarNames).host -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" (printf "%shost" $pgBouncerPrefix) -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_PORT */ -}}
      {{- $varName := default "DB_PORT" (($.Values.database).envVarNames).port -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" (printf "%sport" $pgBouncerPrefix) -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_DATABASE */ -}}
      {{- $varName := default "DB_DATABASE" (($.Values.database).envVarNames).dbname -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" "dbname" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_USER */ -}}
      {{- $varName := default "DB_USER" (($.Values.database).envVarNames).user -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" "user" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_PASS */ -}}
      {{- $varName := default "DB_PASS" (($.Values.database).envVarNames).password -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" "password" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env -}}

    {{- end -}}
  {{- else if ((.Values.database).external).enabled -}}
    {{- /* Check to see if supported credentials type is being used */ -}}
    {{- $credentialsType := default "k8sSecret" (.Values.database.external.credentials).type -}}
    {{- if not (contains $credentialsType "sscsi k8sSecret")  -}}
      {{- fail (printf "Secrets of type `%s` are not supported. Please use `sscsi` or `k8sSecret`" $credentialsType) -}}
    {{- end -}}
    {{- $dbValues := .Values.database -}}
    {{- range $v := $dbValues.external.databases -}}
      {{- $secretName := $v.secretName -}}
      {{- /* envPrefix and Module is only required if using multiple databases.*/ -}}
      {{- $envPrefix := "" -}}
      {{- if gt (len $dbValues.external.databases) 1 -}}
        {{- $module = required "You must provide a modulename that uses the DB secret" $v.module -}}
        {{- $envPrefix = printf "%s_" ( upper $module ) -}}
      {{- end -}}
      {{- $secretKeyRef := dict "name" $secretName -}}
      {{- $keyMap := dict -}}

      {{- /*
      For each DB environment var, first check for an explicitly
      set value. If none, then check for a specified secret key.
      If none, try a default secret key.
      If there is no such key in the secret, then this will fail
      at pod launch as K8s will not be able to mount the secret
      into the environment.
      */ -}}

      {{- /* Define and add DB_TYPE -}}
      {{- $varName := default "DB_TYPE" (($dbValues).envVarNames).dbtype -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- $keyMap = dict "key" "dbtype" -}}
      {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- $envVars = append $envVars $env */ -}}

      {{- /* Define and add DB_URL
             Accepts `url`, `urlKey`, `host` or `hostKey`
      */ -}}
      {{- $varName := default "DB_URL" (($dbValues).envVarNames).host -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- if hasKey $v "url" -}}
        {{- $_ := set $env "value" $v.url -}}
      {{- else if hasKey $v "host" -}}
        {{- $_ := set $env "value" $v.host -}}
      {{- else if hasKey $v "urlKey" -}}
        {{- $keyMap = dict "key" $v.urlKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else if hasKey $v "hostKey" -}}
        {{- $keyMap = dict "key" $v.hostKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
        {{- /* Defaults to `host` */ -}}
      {{- else -}}
        {{- $keyMap = dict "key" "host" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_PORT */ -}}
      {{- $varName := default "DB_PORT" (($dbValues).envVarNames).port -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- if hasKey $v "port" -}}
        {{- $_ := set $env "value" (toString $v.port) -}}
      {{- else if hasKey $v "portKey" -}}
        {{- $keyMap = dict "key" $v.portKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "port" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_DATABASE */ -}}
      {{- $varName := default "DB_DATABASE" (($dbValues).envVarNames).dbname -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- if hasKey $v "dbname" -}}
        {{- $_ := set $env "value" $v.dbname -}}
      {{- else if hasKey $v "dbnameKey" -}}
        {{- $keyMap = dict "key" $v.dbnameKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "dbname" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_USER
             Accepts `user`, `userKey`, `username` or `usernameKey`
      */ -}}
      {{- $varName := default "DB_USER" (($dbValues).envVarNames).user -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- if hasKey $v "user" -}}
        {{- $_ := set $env "value" $v.user -}}
      {{- else if hasKey $v "username" -}}
        {{- $_ := set $env "value" $v.username -}}
      {{- else if hasKey $v "userKey" -}}
        {{- $keyMap = dict "key" $v.userKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else if hasKey $v "usernameKey" -}}
        {{- $keyMap = dict "key" $v.usernameKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "username" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}

      {{- /* Define and add DB_PASS */ -}}
      {{- $varName := default "DB_PASS" (($dbValues).envVarNames).password -}}
      {{- $env := dict "name" (printf "%s%s" $envPrefix $varName) -}}
      {{- if hasKey $v "passKey" -}}
        {{- $keyMap = dict "key" $v.passKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "password" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}
    {{- end -}}
  {{- /* else -}}
    {{- fail "You must either configure an external database (`database.external.enabled: true`) or crunchypgo (`database.crunchypgo.enabled: true`)" */ -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}
