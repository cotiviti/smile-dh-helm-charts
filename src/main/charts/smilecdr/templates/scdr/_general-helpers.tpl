{{- /* Recursive function to un-flatten a dict object
    For example, a dict with a key named as so:
    `config.item.name`
    will become
    ```
    config:
      item:
        name: value
    ```
    To use, just pass in a dict object like so:

    */ -}}
{{- define "sdhCommon.unFlattenDict" -}}
  {{- $srcDict := . -}}
  {{- $newDict := dict -}}
  {{- range $key, $val := $srcDict -}}
    {{- $parts := splitList "." $key -}}
    {{- $numParts := len $parts -}}
    {{- $tmpDict := $newDict -}}
    {{- range $i, $keyName := $parts -}}
      {{- if not (hasKey $tmpDict $keyName) -}}
        {{- /* Only add the value if it's the last/only entry.
            Otherwise add an empty `dict` */ -}}
        {{- if eq $i (sub $numParts 1) -}}
          {{- $_ := set $tmpDict $keyName $val -}}
        {{- else -}}
          {{- $_ := set $tmpDict $keyName dict -}}
        {{- end -}}
      {{- end -}}
      {{- $tmpDict = index $tmpDict $keyName -}}
    {{- end -}}
  {{- end -}}
  {{- $newDict | toYaml -}}
{{- end -}}

{{- /* Recursive function to flatten a dict object
    The inverse of unflattendict above.
    Used, for now, to rebuild module configurations
    */ -}}
{{- define "sdhCommon.flattenDict" -}}
  {{- $srcDict := $.srcDict -}}

  {{- $keyNamePrefix := "" -}}
  {{- if ($.parentKeyName) -}}
    {{- $keyNamePrefix = printf "%s." $.parentKeyName -}}
  {{- end -}}

  {{- $newDict := dict -}}
  {{- range $key, $val := $srcDict -}}
    {{- /* If it's a dict, recurse. Otherwise append to newDict */ -}}
    {{- if (typeIs "map[string]interface {}" $val) -}}
      {{- $subDict := include "sdhCommon.flattenDict" (dict "srcDict" $val "parentKeyName" (printf "%s%s" $keyNamePrefix $key) ) | fromYaml -}}
      {{- $newDict = merge $newDict $subDict -}}
    {{- else -}}
      {{- $_ := set $newDict (printf "%s%s" $keyNamePrefix $key) $val -}}
    {{- end -}}
  {{- end -}}
  {{- $newDict | toYaml -}}
{{- end -}}

{{- /* Helper template to make flattendict easier to use*/ -}}
{{- define "sdhCommon.flattenConf" -}}
  {{- include "sdhCommon.flattenDict" (dict "srcDict" .) -}}
{{- end -}}
