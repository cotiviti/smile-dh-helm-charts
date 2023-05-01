{{/*
These helper templates are used to configure persistent storage backend configurations for Directus.
Currently it only supports AWS S3 backends
*/}}

{{- /*
This template defines environment variables
*/ -}}
{{- define "directus.storageEnvVars" -}}
{{- $envVars := list -}}
{{- $storageLocations := "" -}}
{{- if .Values.fileStorage.s3.enabled -}}
   {{- $storageLocations = "s3" -}}
   {{- $envVars = append $envVars (dict "name" "STORAGE_S3_DRIVER" "value" "s3") -}}
   {{- $envVars = append $envVars (dict "name" "STORAGE_S3_BUCKET" "value" .Values.fileStorage.s3.bucketName) -}}
   {{- $envVars = append $envVars (dict "name" "STORAGE_S3_ROOT" "value" .Values.fileStorage.s3.bucketPrefix) -}}
   {{- $envVars = append $envVars (dict "name" "STORAGE_S3_REGION" "value" .Values.fileStorage.s3.bucketRegion) -}}
   {{/* - $envVars = append $envVars (dict "name" "STORAGE_S3_ENDPOINT" "value" "s3.amazonaws.com") - */}}
{{- end -}}
{{- $envVars = append $envVars (dict "name" "STORAGE_LOCATIONS" "value" $storageLocations) -}}
{{- $envVars | toYaml -}}
{{- end -}}
