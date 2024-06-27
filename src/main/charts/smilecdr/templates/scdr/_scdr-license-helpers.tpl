{{- define "smilecdr.license" -}}
  {{- $licenseConfig := dict -}}
  {{- if $.Values.license -}}
    {{- /* Set up the secret for Smile CDR License */ -}}
    {{- $_ := set $licenseConfig "enabled" true -}}
    {{- $secretSpec := deepCopy $.Values.license -}}
    {{- $_ := set $secretSpec "volumeName" "license-volume" -}}
    {{- $_ := set $secretSpec "secretName" "cdrlicense" -}}
    {{- /* $_ := set $secretSpec "secretName" "license.jwt" */ -}}
    {{- $_ := set $secretSpec "secretKeyMap" dict -}}
    {{- $directCopy := true -}}
    {{- $_ := set $licenseConfig "directCopy" $directCopy -}}
    {{- if $directCopy -}}
      {{- $_ := set $secretSpec.secretKeyMap "license.jwt" (dict "secretKeyName" "jwt" "k8sSecretKeyName" "jwt") -}}
    {{- else -}}
      {{- $_ := set $secretSpec.secretKeyMap "license.jwt" (dict "secretKeyName" "jwt" "k8sSecretKeyName" "jwt" "mountSpec" (dict "mountPath" "/home/smile/smilecdr/classes/license.jwt")) -}}
    {{- end -}}
    {{- $_ := set $secretSpec "useKeyMapAsAlias" true -}}
    {{- $_ := set $secretSpec "objectAliasDisabled" true -}}
    {{- $_ := set $secretSpec "syncSecret" true -}}
    {{- $secretConfig := include "sdhCommon.secretConfig" (dict "rootCTX" $ "secretSpec" $secretSpec) | fromYaml -}}
    {{- $_ := set $licenseConfig "secret" $secretConfig -}}

  {{- end -}}
  {{- $licenseConfig | toYaml -}}
{{- end -}}
