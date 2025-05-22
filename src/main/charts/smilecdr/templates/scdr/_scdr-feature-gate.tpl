{{- /* Feature Gates
     *
     * This helper file con tains a feature gate for determining which features can be used
     * for which versions of Smile CDR
     */ -}}

{{- define "smilecdr.features.getFeatureDetails" -}}
  {{- $featureId := index . 0 -}}
  {{- /* $cdrVersion := toString (index . 1) */ -}}
  {{- $cdrVersion := index . 1 -}}

  {{- $matrix := include "smilecdr.features.matrix" . | fromYaml -}}
  {{- $feature := index $matrix $featureId -}}

  {{- $featureDetails := dict "canUse" false "isDeprecated" false -}}

  {{- if $feature -}}
    {{- $min := default "2024.05" $feature.min -}}
    {{- $max := default "9999.99" $feature.max -}}

    {{- $version := regexFind "[0-9]{4}\\.[0-9]{2}" $cdrVersion -}}

    {{- if and
        (semverCompare (printf ">= %s" $min) $version)
        (semverCompare (printf "<= %s" $max) $version)
      -}}
      {{- $_ := set $featureDetails "canUse" true -}}
    {{- end -}}
  {{- end -}}
  {{- $featureDetails | toYaml -}}
{{- end }}

{{- define "smilecdr.features.matrix" -}}
  {{- $features := dict
    "f002" (dict "name" "AwsAdvancedJDBCDriver" "min" "2025.05")
    "f001" (dict "name" "NodeEnvironmentType" "min" "2024.08")
  -}}
  {{- $features | toYaml -}}
{{- end }}

{{- /* Smile CDR Version Check
     * Each version of the Helm Chart can only officially support
     * specific versions of Smile CDR, based on the version that
     * the Helm Chart was published with.
     *
     */ -}}
{{- define "smilecdr.checkVersion" -}}
  {{- $cdrVersion := toString . -}}
  {{- $result := dict "supported" false "error" "" -}}
  {{- $releases := include "smilecdr.releases" . | fromYaml -}}

  {{- $cdrRelease := regexFind "[0-9]{4}\\.[0-9]{2}" $cdrVersion -}}
  {{- /* if not (index $releases $cdrRelease) -}}
    {{- fail (printf "\nUnsupported Smile CDR version: %s\n\nPlease select an available version from the following Smile CDR releases:\n* %s" $cdrVersion (join "\n* " (keys $releases))) -}}
  {{- end */ -}}
  {{- if (index $releases $cdrRelease) -}}
    {{- $_ := set $result "supported" true -}}
  {{- else -}}
    {{- $_ := set $result "supported" false -}}
    {{- $_ := set $result "error" (printf "\nUnsupported Smile CDR version: %s\n\nPlease select an available version from the following Smile CDR releases:\n* %s" $cdrVersion (join "\n* " (keys $releases))) -}}
  {{- end -}}
  {{- /* fail (printf "%s" $result) */ -}}
  {{- $result | toYaml -}}
{{- end -}}

{{- /* Smile CDR Version Matrix
     *
     */ -}}
{{- define "smilecdr.releases" -}}
  {{- $releases := dict
    "2025.05" (dict "name" "Fortification" "latest" "R01")
    "2025.02" (dict "name" "Transfiguration" "latest" "R03")
    "2024.11" (dict "name" "Despina" "latest" "R05")
    "2024.08" (dict "name" "Copernicus" "latest" "R05")
    "2024.05" (dict "name" "Borealis" "latest" "R05")
    "2024.02" (dict "name" "Apollo" "latest" "R07")
    "2023.11" (dict "name" "Zed" "latest" "R05")
    "2023.08" (dict "name" "Yucatán" "latest" "R09")
  -}}
  {{- $releases | toYaml -}}
{{- end }}
