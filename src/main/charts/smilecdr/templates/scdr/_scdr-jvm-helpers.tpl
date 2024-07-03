{{/*
Smile CDR JVM settings helper
Creates JVM args based on:
* Pod requests.memory
* JVM factor
* JVM Xms setting
* Extra JVM Args
*/}}
{{- define "smilecdr.jvmargs" -}}
  {{- $jvmArgs := "-server" -}}
  {{- $jvmHeapBytes := (default (mulf 2048 1024 ) ( include "k8s.suffixToValue" .Values.resources.limits.memory )) -}}
  {{- if .Values.resources.requests.memory -}}
    {{- $jvmHeapBytes = ( include "k8s.suffixToValue" .Values.resources.requests.memory ) -}}
  {{- end -}}
  {{- $jvmHeapBytes = mulf $jvmHeapBytes .Values.jvm.memoryFactor -}}
  {{- $jvmHeapBytesString := ( include "k8s.bytesToJavaSuffix" $jvmHeapBytes ) -}}
  {{- if .Values.jvm.xms -}}
    {{- $jvmArgs = printf "%s -Xms%s" $jvmArgs $jvmHeapBytesString  -}}
  {{- end -}}
  {{- $jvmArgs = printf "%s -Xmx%s" $jvmArgs $jvmHeapBytesString  -}}
  {{- range $v := .Values.jvm.args -}}
    {{- $jvmArgs = printf "%s %s" $jvmArgs $v -}}
  {{- end -}}
  {{- $jvmArgs -}}
{{- end -}}

{{/*
K8s Quantity conversion
Takes a bytes value with Kubernetes style suffix (`k`, `M`, `G`, `Ki`, `Mi` or `Gi`) and
converts it to the raw bytes value
*/}}
{{- define "k8s.suffixToValue" -}}
  {{- $inVal := . | toString -}}
  {{- $rawVal := $inVal -}}
  {{- if hasSuffix "Gi" $inVal -}}
    {{- $rawVal = ( mulf 1024 1024 1024 ( trimSuffix "Gi" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "Mi" $inVal -}}
    {{- $rawVal = ( mulf 1024 1024 ( trimSuffix "Mi" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "Ki" $inVal -}}
    {{- $rawVal = ( mulf 1024 ( trimSuffix "Ki" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "G" $inVal -}}
    {{- $rawVal = ( mulf 1000000000 ( trimSuffix "G" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "M" $inVal -}}
    {{- $rawVal = ( mulf 1000000 ( trimSuffix "M" $inVal ) | float64 ) | int -}}
  {{- else if hasSuffix "k" $inVal -}}
    {{- $rawVal = ( mulf 1000 ( trimSuffix "k" $inVal ) | float64 ) | int -}}
  {{- end -}}
  {{- $rawVal | float64 | int -}}
{{- end -}}

{{/*
K8s Quantity conversion
Takes a raw bytes value and adds a Java style suffix (`k` or `m`)
*/}}
{{- define "k8s.bytesToJavaSuffix" -}}
  {{- $bytes := . | int -}}
  {{- $Gi := mul 1024 1024 1024 -}}
  {{- $Mi := mul 1024 1024 -}}
  {{- $Ki := mul 1024 -}}
  {{- $outBytes := $bytes -}}
  {{- if gt $bytes $Mi -}}
    {{- $outBytes = printf "%sm" (trunc 5 ( divf $bytes $Mi | int | toString )) -}}
  {{- else if gt $bytes $Ki -}}
    {{- $outBytes = printf "%sk" (trunc 5 ( divf $bytes $Ki | int | toString )) -}}
  {{- end -}}
  {{- $outBytes | toString -}}
{{- end -}}
