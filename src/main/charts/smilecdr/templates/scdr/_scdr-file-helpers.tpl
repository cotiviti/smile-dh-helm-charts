{{/*
These helper templates are used to help import files into the environment
using ConfigMaps
*/}}

{{- /*
This template helps create a configMap for each file that is defined in the
.Values.mappedFiles section.
It expects that there should also be a .Values.mappedFiles.filename.data section
that contains the file contents, as passed in by the --set-file helm install option.
If a file is added to mappedFiles, but does not have a `data` key, then it will be
quietly ignored.
*/ -}}
{{- define "smilecdr.fileConfigMaps" -}}
{{- $fileCfgMaps := list -}}
{{- if gt (len .Values.mappedFiles) 0 -}}
  {{- range $k, $v := .Values.mappedFiles -}}
    {{- if hasKey $v "data" -}}
      {{- $fileCfgMaps = append $fileCfgMaps (dict "name" ( $k ) "data" $v.data "hash" ( sha256sum $v.data )) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $fileCfgMaps | toYaml -}}
{{- end -}}

{{/*
Define fileVolumes for all mapped files
*/}}
{{ define "smilecdr.fileVolumes" }}
  {{- $fileVolumes := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $cmName := printf "%s-scdr-%s" $.Release.Name ($k | replace "." "-") -}}
      {{- if and $.Values.autoDeploy (hasKey $v "data") -}}
        {{- $cmName = printf "%s-%s" $cmName (sha256sum ($v.data)) -}}
      {{- end -}}
      {{- $fileVolume := dict "name" ($k | replace "." "-") -}}
      {{- $_ := set $fileVolume "configMap" (dict "name" $cmName) -}}
      {{- $fileVolumes = append $fileVolumes $fileVolume -}}
    {{- end -}}
  {{- end -}}
  {{- /* Add init-sync shared volumes for classes and customerlib if enabled */ -}}
  {{- if or (hasKey .Values.copyFiles "classes") (hasKey .Values "license") -}}
    {{- $fileVolume := dict "name" "scdr-volume-classes" -}}
    {{- $_ := set $fileVolume "emptyDir" (dict "sizeLimit" "500Mi") -}}
    {{- $fileVolumes = append $fileVolumes $fileVolume -}}
  {{- end -}}
  {{- if hasKey .Values.copyFiles "customerlib" -}}
    {{- $fileVolume := dict "name" "scdr-volume-customerlib" -}}
    {{- $_ := set $fileVolume "emptyDir" (dict "sizeLimit" "500Mi") -}}
    {{- $fileVolumes = append $fileVolumes $fileVolume -}}
  {{- end -}}
  {{- $fileVolumes | toYaml -}}
{{- end -}}

{{/*
Define fileVolumeMounts for all mapped files
*/}}
{{ define "smilecdr.fileVolumeMounts" }}
  {{- $fileVolumeMounts := list -}}
  {{- if gt (len .Values.mappedFiles) 0 -}}
    {{- range $k, $v := .Values.mappedFiles -}}
      {{- $fileVolumeMount := dict "name" ($k | replace "." "-") -}}
      {{- $_ := set $fileVolumeMount "mountPath" (printf "%s/%s" (default "/home/smile/smilecdr/classes" $v.path) $k) -}}
      {{- $_ := set $fileVolumeMount "subPath" $k -}}
      {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- /* Add init-sync shared volumes for classes and customerlib if enabled */ -}}
  {{- if or (hasKey .Values.copyFiles "classes") (hasKey .Values "license") -}}
    {{- $fileVolumeMount := dict "name" "scdr-volume-classes" -}}
    {{- $_ := set $fileVolumeMount "mountPath" "/home/smile/smilecdr/classes" -}}
    {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
  {{- end -}}
  {{- if hasKey .Values.copyFiles "customerlib" -}}
    {{- $fileVolumeMount := dict "name" "scdr-volume-customerlib" -}}
    {{- $_ := set $fileVolumeMount "mountPath" "/home/smile/smilecdr/customerlib" -}}
    {{- $fileVolumeMounts = append $fileVolumeMounts $fileVolumeMount -}}
  {{- end -}}
  {{- $fileVolumeMounts | toYaml -}}
{{ end }}

{{/*
Define init-pull containers

Note:
We are defining volumeMounts for these init containers directly rather than in smilecdr.fileVolumeMounts
because these init containers do not need any of the files mapped by configMaps.
Volumes are defined in `smilecdr.fileVolumes`
*/}}
{{ define "smilecdr.initFileContainers" }}
  {{- $initPullContainers := list -}}
  {{- $initContainerResources := (dict "requests" (dict "cpu" "500m" "memory" "500Mi")) -}}
  {{- $_ := set $initContainerResources "limits" (dict "cpu" "500m" "memory" "500Mi") -}}
  {{- if or (hasKey .Values.copyFiles "classes") (hasKey .Values "license") -}}
    {{- if not ((.Values.copyFiles.classes).disableSyncDefaults) -}}
      {{- $imageSpec := dict "name" "init-sync-classes" -}}
      {{- $_ := set $imageSpec "image" (printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag)) -}}
      {{- $_ := set $imageSpec "imagePullPolicy" .Values.image.pullPolicy -}}
      {{- $_ := set $imageSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/classes/* /tmp/smilecdr-volumes/classes/")  -}}
      {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
      {{- $initPullContainers = append $initPullContainers $imageSpec -}}
    {{- end -}}
    {{- range $v := (.Values.copyFiles.classes).sources -}}
      {{- if eq $v.type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy classes files from." $v.bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy classes files from." $v.path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $imageSpec := dict "name" "init-pull-classes-s3" -}}
        {{- $_ := set $imageSpec "image" "public.ecr.aws/aws-cli/aws-cli" -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/classes/" "--recursive" )  -}}
        {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else if eq .type "curl" -}}
        {{- $url := required "You must specify a URL to copy classes files from." .url -}}
        {{- $fileName := required "You must specify a destination `fileName` for classes files." .fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/classes/%s" $fileName -}}
        {{- $imageSpec := dict "name" "init-pull-classes-curl" -}}
        {{- $_ := set $imageSpec "image" "curlimages/curl" -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- if hasKey .Values.copyFiles "customerlib" -}}
    {{- if not ((.Values.copyFiles.customerlib).disableSyncDefaults) -}}
      {{- $imageSpec := dict "name" "init-sync-customerlib" -}}
      {{- $_ := set $imageSpec "image" (printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag)) -}}
      {{- $_ := set $imageSpec "imagePullPolicy" .Values.image.pullPolicy -}}
      {{- $_ := set $imageSpec "command" (list "/bin/sh" "-c" "/bin/cp -Rvp /home/smile/smilecdr/customerlib/* /tmp/smilecdr-volumes/customerlib/")  -}}
      {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
      {{- $_ := set $imageSpec "resources" $initContainerResources -}}
      {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
      {{- $initPullContainers = append $initPullContainers $imageSpec -}}
    {{- end -}}
    {{- range .Values.copyFiles.customerlib.sources -}}
      {{- if eq .type "s3" -}}
        {{- $bucket := required "You must specify an S3 bucket to copy customerlib files from." .bucket -}}
        {{- $bucketPath := required "You must specify an S3 bucket path to copy customerlib files from." .path -}}
        {{- $bucketFullPath := printf "s3://%s%s" $bucket $bucketPath -}}
        {{- $imageSpec := dict "name" "init-pull-customerlib-s3" -}}
        {{- $_ := set $imageSpec "image" "public.ecr.aws/aws-cli/aws-cli" -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "s3" "cp" $bucketFullPath "/tmp/smilecdr-volumes/customerlib/" "--recursive" )  -}}
        {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else if eq .type "curl" -}}
        {{- $url := required "You must specify a URL to copy customerlib files from." .url -}}
        {{- $fileName := required "You must specify a destination `fileName` for customerlib files." .fileName -}}
        {{- $fileFullPath := printf "/tmp/smilecdr-volumes/customerlib/%s" $fileName -}}
        {{- $imageSpec := dict "name" "init-pull-customerlib-curl" -}}
        {{- $_ := set $imageSpec "image" "curlimages/curl" -}}
        {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
        {{- $_ := set $imageSpec "args" (list "-o" $fileFullPath "--location" "--create-dirs" $url )  -}}
        {{- $_ := set $imageSpec "securityContext" $.Values.securityContext -}}
        {{- $_ := set $imageSpec "resources" $initContainerResources -}}
        {{- $_ := set $imageSpec "volumeMounts" (list (dict "name" "scdr-volume-customerlib" "mountPath" "/tmp/smilecdr-volumes/customerlib/")) -}}
        {{- $initPullContainers = append $initPullContainers $imageSpec -}}
      {{- else -}}
        {{- fail "Currently only supports S3 or curl for pulling extra files" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Define init containers for license copying.
         Sync container was already defined above if there was a license. */ -}}
  {{- if hasKey .Values "license" -}}
    {{- $imageSpec := dict "name" "copy-cdr-license" -}}
    {{- $_ := set $imageSpec "image" "alpine:3" -}}
    {{- $_ := set $imageSpec "imagePullPolicy" "IfNotPresent" -}}
    {{- $_ := set $imageSpec "args" (list "cp" "/mnt/sscsi/license.jwt" "/tmp/smilecdr-volumes/classes/" )  -}}
    {{- $_ := set $imageSpec "securityContext" .Values.securityContext -}}
    {{- $_ := set $imageSpec "resources" $initContainerResources -}}
    {{- $_ := set $imageSpec "volumeMounts" (append (include "smilecdr.volumeMounts" . | fromYamlArray) (dict "name" "scdr-volume-classes" "mountPath" "/tmp/smilecdr-volumes/classes/")) -}}
    {{- $initPullContainers = append $initPullContainers $imageSpec -}}
  {{- end -}}
  {{- $initPullContainers | toYaml -}}
{{ end }}
