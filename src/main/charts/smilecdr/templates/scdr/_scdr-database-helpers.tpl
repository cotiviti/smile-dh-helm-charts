{{/*
Define SmileCDR DB Environment
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
      {{- $username := $v.name -}}
      {{- $module := default $username $v.module -}}

      {{- $envPrefix := printf "%s_" ( upper $module ) -}}
      {{- /*
      If there is only a single DB, don't use a prefix as the same
      environment variables will be shared amongst all modules
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
  {{- else if .Values.database.external.enabled -}}
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

      {{- /* Define and add DB_URL */ -}}
      {{- $env := dict "name" (printf "%sDB_URL" $envPrefix) -}}
      {{- if hasKey $v "url" -}}
        {{- $_ := set $env "value" $v.url -}}
      {{- else if hasKey $v "urlKey" -}}
        {{- $keyMap = dict "key" $v.urlKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "url" -}}
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

      {{- /* Define and add DB_USER */ -}}
      {{- $env := dict "name" (printf "%sDB_USER" $envPrefix) -}}
      {{- if hasKey $v "user" -}}
        {{- $_ := set $env "value" $v.user -}}
      {{- else if hasKey $v "userKey" -}}
        {{- $keyMap = dict "key" $v.userKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (merge (deepCopy $secretKeyRef) $keyMap)) -}}
      {{- else -}}
        {{- $keyMap = dict "key" "user" -}}
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
  {{- /* Render the environments */ -}}
  {{- if ne (len $envVars) 0 -}}
    {{- printf "%v" (toYaml $envVars) -}}
  {{- end -}}
{{- end -}}
