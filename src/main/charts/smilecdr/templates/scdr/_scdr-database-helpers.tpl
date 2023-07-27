{{/*
Define Smile CDR DB Environment
Environment variables for databases
*/}}
{{- define "smilecdr.dbEnvVars" -}}
  {{- $envVars := list -}}
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
        {{- /*
        If there is only a single DB, don't use an environment variable prefix as
        the same environment variables will be shared amongst all modules.
        */ -}}
        {{- if le (len $.Values.database.crunchypgo.users) 1 -}}
          {{- $envPrefix = "" -}}
        {{- end -}}

        {{- $secretName := printf "%s-pguser-%s" $crunchyReleaseName $username -}}
        {{- $secretKeyRef := dict "name" $secretName -}}
        {{- $pgBouncerPrefix := (ternary "pgbouncer-" "" (hasKey $.Values.database.crunchypgo.config "pgBouncerConfig")) -}}
        {{- $keyMap := dict -}}

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
  {{- else if .Values.database.external.enabled -}}
    {{- /* Check to see if supported credentials type is being used */ -}}
    {{- $credentialsType := default "k8sSecret" (.Values.database.external.credentials).type -}}
    {{- if not (contains $credentialsType "sscsi k8sSecret")  -}}
      {{- fail (printf "Secrets of type `%s` are not supported. Please use `sscsi` or `k8sSecret`" $credentialsType) -}}
    {{- end -}}
    {{- range $v := .Values.database.external.databases -}}
      {{- $secretName := $v.secretName -}}
      {{- $module := required "You must provide a modulename that uses the DB secret" $v.module -}}

      {{- $envPrefix := printf "%s_" ( upper $module ) -}}
      {{- /*
      If there is only a single DB, don't use a prefix as the same
      environment variables will be shared amongst all modules
      */ -}}
      {{- if le (len $.Values.database.external.databases) 1 -}}
        {{- $envPrefix = "" -}}
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

      {{- /* Define and add DB_URL
             Accepts `url`, `urlKey`, `host` or `hostKey`
      */ -}}
      {{- $env := dict "name" (printf "%sDB_URL" $envPrefix) -}}
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
      {{- $env := dict "name" (printf "%sDB_PORT" $envPrefix) -}}
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
      {{- $env := dict "name" (printf "%sDB_DATABASE" $envPrefix) -}}
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
      {{- $env := dict "name" (printf "%sDB_USER" $envPrefix) -}}
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
      {{- $env := dict "name" (printf "%sDB_PASS" $envPrefix) -}}
      {{- if hasKey $v "passKey" -}}
        {{- $keyMap = dict "key" $v.passKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "password" -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}
    {{- end -}}
  {{- else -}}
    {{- fail "You must either configure an external database (`database.external.enabled: true`) or crunchypgo (`database.crunchypgo.enabled: true`)" -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}
