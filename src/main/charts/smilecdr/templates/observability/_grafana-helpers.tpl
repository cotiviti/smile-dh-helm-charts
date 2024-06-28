
{{- define "observability.grafana.enabled" -}}
  {{- if and .Values.observability.enabled .Values.observability.dashboard.grafana.enabled -}}
    {{- true -}}
  {{- end -}}
{{- end -}}

{{- define "observability.grafanaoperator.enabled" -}}
  {{- if and (include "observability.grafana.enabled" .) .Values.observability.dashboard.grafana.useOperator -}}
    {{- true -}}
  {{- end -}}
{{- end -}}

{{- define "observability.grafana.host" -}}
  {{- $grafHost := .Values.specs.hostname -}}
  {{- if and .Values.observability.dashboard.grafana.ingress.host (ne .Values.observability.dashboard.grafana.ingress.host "main") -}}
    {{- $grafHost = .Values.observability.dashboard.grafana.ingress.host -}}
  {{- end -}}
  {{- $grafHost -}}
{{- end -}}

{{- define "observability.grafana.rooturl" -}}
  {{- $grafPath := default "grafana" .Values.observability.dashboard.grafana.ingress.path -}}
  {{- printf "https://%s/%s" (include "observability.grafana.host" .) (trimPrefix "/" $grafPath) -}}
{{- end -}}

{{- define "observability.grafana.ingressClassName" -}}
  {{- default "nginx" .Values.observability.dashboard.grafana.ingress.ingressClassName -}}
{{- end -}}

{{- define "observability.grafana.ingress.rules" -}}
  {{- $rules := list -}}
  {{- $grafHost := include "observability.grafana.host" . -}}
  {{- $grafPath := default "grafana" (.Values.observability.dashboard.grafana.ingress.path) -}}
  {{- $grafPort := default 3000 (.Values.observability.dashboard.grafana.ingress.port) -}}

  {{- $serviceObject := dict "name" (printf "%s-grafana-service" $.Release.Name ) "port" (dict "number" $grafPort) -}}
  {{- $pathObject := dict "path" $grafPath "pathType" "Prefix" "backend" (dict "service" $serviceObject) -}}
  {{- $hostPaths := dict "paths" (list $pathObject) -}}

  {{- $rule := dict "host" $grafHost "http" $hostPaths -}}
  {{- $rules = append $rules $rule -}}
  {{- $rules | toYaml -}}
{{- end -}}

{{- define "observability.grafana.datasource.loki" -}}
  {{- $dsConfig := dict "name" "Loki" -}}
  {{- $_ := set $dsConfig "type" "loki" -}}
  {{- $_ := set $dsConfig "resourceName" (lower $dsConfig.name) -}}
  {{- $_ := set $dsConfig "inputName" "DS_LOKI" -}}

  {{- $dsConfig | toYaml -}}
{{- end -}}

{{- define "observability.grafana" -}}
  {{- $grafanaConfig := dict -}}
  {{- $observabilityValues := .Values.observability -}}
  {{- if and $observabilityValues.enabled $observabilityValues.dashboard.grafana.enabled -}}
    {{- $grafanaValues := $observabilityValues.dashboard.grafana -}}
    {{- $_ := set $grafanaConfig "enabled" true -}}
    {{- /* Add Settings Below */ -}}

    {{- /* Data Sources*/ -}}
    {{- $dataSources := list -}}
    {{- /* Logs */ -}}
    {{- if $observabilityValues.instrumentation.logging.enabled -}}
      {{- $logsDataSourceEndpoint := "" -}}
      {{- if $observabilityValues.services.logging.loki.enabled -}}
        {{- $lokiDatasourceConfig := include "observability.grafana.datasource.loki" . | fromYaml -}}
        {{- if ((($grafanaValues.externalDataSources).logging).loki).enabled -}}
          {{- $logsDataSourceEndpoint = required "You must provide `externalEndpoint` if using external Loki instance" $grafanaValues.externalDataSources.logging.loki.externalEndpoint -}}
        {{- else -}}
          {{- /* Use auto-provisioned loki */ -}}
          {{- /* TODO: Somehting like printf "http://%s-loki:3100"  .Release.Name */ -}}
          {{- /* $logsDataSourceEndpoint = "http://loki:3100/loki/api/v1/push" */ -}}
          {{- $logsDataSourceEndpoint = "http://loki:3100" -}}
        {{- end -}}
        {{- $lokiDataSource := omit $lokiDatasourceConfig "inputName" -}}
        {{- /* $_ := set $lokiDataSource "type" $lokiDatasourceConfig.type -}}
        {{- $_ := set $lokiDataSource "resourceName" $lokiDatasourceConfig.resourceName */ -}}
        {{- $_ := set $lokiDataSource "url" $logsDataSourceEndpoint -}}
        {{- /* $_ := set $lokiDataSource "basicAuth" false */ -}}
        {{- /* $_ := set $lokiDataSource "isDefault" false */ -}}
        {{- $jsonData := dict "tlsSkipVerify" true -}}
        {{- $_ := set $jsonData "timeInterval" "5s" -}}
        {{- /* If Tempo is enabled, for linking Spans to logs */ -}}
        {{- $derivedFields := list -}}
        {{- if false -}}
          {{- $tempoField := dict "name" "traceId" -}}
          {{- /* TODO: Determine Tempo DataSource ID
          {{- $_ := set $tempoField "datasourceUid" "Tempo" -}}
          */ -}}
          {{- $_ := set $tempoField "matcherRegex" "(?:X-Request-Id)=(\\w+)" -}}
          {{- $_ := set $tempoField "url" "$${__value.raw}" -}}
          {{- $derivedFields = append $derivedFields $tempoField -}}
        {{- end -}}
        {{- /* Optionally add code here to add other derived fields before adding them to
            the jsonData */ -}}
        {{- if gt (len $derivedFields) 0 -}}
          {{- $_ := set $jsonData "derivedFields" $derivedFields -}}
        {{- end -}}
        {{- $_ := set $lokiDataSource "jsonData" $jsonData -}}
        {{- $_ := set $lokiDataSource "editable" false -}}

        {{- $dataSources = append $dataSources $lokiDataSource -}}
      {{- end -}}
    {{- end -}}

    {{- $_ := set $grafanaConfig "dataSources" $dataSources -}}
  {{- else -}}
    {{- $_ := set $grafanaConfig "enabled" false -}}
  {{- end -}}
  {{- $grafanaConfig | toYaml -}}
{{- end -}}


{{- /* Helper functions to define Grafana Data Sources */ -}}

{{- define "observability.grafana.datasources" -}}
  {{- $grafanaDashboards := dict -}}
  {{- $_ := set $grafanaDashboards "key" "value" -}}



  {{- $grafanaDashboards | toYaml -}}
{{- end -}}

{{- /* Helper functions to define Grafana Dashboards */ -}}

{{- define "observability.grafana.dashboards" -}}
  {{- $grafanaDashboards := dict -}}

  {{- if ((.Values.observability.services).logging).enabled -}}
    {{- $_ := set $grafanaDashboards "smilecdr-logs" (include "observability.grafana.dashboard.smilecdr-logs" . | fromYaml) -}}
  {{- end -}}
  {{- $grafanaDashboards | toYaml -}}
{{- end -}}

{{- define "observability.grafana.dashboard.smilecdr-logs" -}}
  {{- $logsDashboard := dict -}}
  {{- $logsDashboardJson := dict -}}
  {{- $dataSourcesSpec := list -}}

  {{- /* Annotations */ -}}
  {{- /*

  "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "grafana",
              "uid": "-- Grafana --"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "target": {
              "limit": 100,
              "matchAny": false,
              "tags": [],
              "type": "dashboard"
            },
            "type": "dashboard"
          }
        ]
      },

  */ -}}

  {{- $lokiDatasourceConfig := include "observability.grafana.datasource.loki" . | fromYaml -}}
  {{- $dataSourcesSpec = append $dataSourcesSpec (dict "inputName" $lokiDatasourceConfig.inputName "datasourceName" $lokiDatasourceConfig.name ) -}}
  {{- /* Add other required data sources here */ -}}
  {{- $_ := set $logsDashboard "datasources" $dataSourcesSpec -}}

  {{- /* This enables the dynamic datasource assignment */ -}}
  {{- $dsLokiInput := dict "name" $lokiDatasourceConfig.inputName "label" $lokiDatasourceConfig.name "type" "datasource" -}}
  {{- $_ := set $logsDashboardJson "__inputs" (list $dsLokiInput) -}}

  {{- /* This is for inclusion in the individual panels */ -}}
  {{- $lokiDatasource := dict "type" $lokiDatasourceConfig.type "uid" (printf "${%s}" $lokiDatasourceConfig.inputName) -}}

  {{- $panels := list -}}

  {{- $summaryPanels := list -}}
  {{- $summaryPanels = append $summaryPanels (dict "title" "Total Logs" "level" "ALL" "pos" "0")  -}}
  {{- $summaryPanels = append $summaryPanels (dict "title" "Error logs" "level" "ERROR" "pos" "1")  -}}
  {{- $summaryPanels = append $summaryPanels (dict "title" "Warning Logs" "level" "WARN" "pos" "2")  -}}

  {{- $panelWidth := div 24 (len $summaryPanels) -}}
  {{- $panelHeight := 5 -}}

  {{- $selectorElements := list "namespace=~\"$namespace\"" "deployment=~\"$deployment\"" "replicaset=~\"$replicaset\"" "pod=~\"$pod\"" -}}
  {{- range $thePanel := $summaryPanels -}}
    {{- $panelSpec := dict -}}
    {{- $_ := set $panelSpec "type" "timeseries" -}}
    {{- $_ := set $panelSpec "title" $thePanel.title -}}
    {{- $_ := set $panelSpec "datasource" $lokiDatasource -}}
    {{- $_ := set $panelSpec "gridPos" (dict "h" $panelHeight "w" $panelWidth "y" 0 "x" (mul $thePanel.pos $panelWidth))  -}}
    {{- $summarySelectorElements := $selectorElements -}}
    {{- if contains $thePanel.level "ERROR WARN" -}}
      {{- $summarySelectorElements = append $summarySelectorElements (printf "level=`%s`" $thePanel.level) -}}
    {{- end -}}
    {{- $expression := printf "sum(count_over_time({%s} [$__interval]))" (join "," $summarySelectorElements) -}}
    {{- $target := dict "expr" $expression "queryType" "range" -}}
    {{- $_ := set $panelSpec "targets" (list $target) -}}
    {{- $panels = append $panels $panelSpec -}}
  {{- end -}}

  {{- /* Logs Panel */ -}}
  {{- $logsPanelSpec := dict "type" "logs" -}}
  {{- $_ := set $logsPanelSpec "title" "Live Logs" -}}
  {{- $_ := set $logsPanelSpec "datasource" $lokiDatasource -}}
  {{- $_ := set $logsPanelSpec "gridPos" (dict "h" 15 "w" 24 "y" $panelHeight "x" 0)  -}}
  {{- $options := dict "showTime" true "wrapLogMessage" true -}}
  {{- $_ := set $logsPanelSpec "options" $options -}}
  {{- $logSelectorElements := append $selectorElements "level=~\"$level\"" -}}
  {{- $expression := printf "{%s} |~ `$search` | json | line_format `{{.pod}} [{{.attributes_thread_name}}] {{.level}} {{.instrumentation_scope_name}} {{.body}}`" (join "," $logSelectorElements) -}}
  {{- $target := dict "expr" $expression "queryType" "range" -}}
  {{- $_ := set $logsPanelSpec "targets" (list $target) -}}
  {{- $panels = append $panels $logsPanelSpec -}}

  {{- /* Variables */ -}}

  {{- $variableSpecs := list -}}

  {{- $variableDefinitions := list -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "namespace" "label" "Namespace" "type" "query" "queryLabel" "namespace") -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "deployment" "label" "Deployment" "type" "query" "queryLabel" "deployment") -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "replicaset" "label" "ReplicaSet" "type" "query" "queryLabel" "replicaset") -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "pod" "label" "Pod" "type" "query" "queryLabel" "pod") -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "level" "label" "Level" "type" "query" "queryLabel" "level") -}}
  {{- $variableDefinitions = append $variableDefinitions (dict "name" "search" "label" "Search" "type" "textbox") -}}
  {{- range $theVariable := $variableDefinitions -}}
    {{- $theListSpec := dict "name" $theVariable.name -}}
    {{- $_ := set $theListSpec "type" $theVariable.type -}}
    {{- $_ := set $theListSpec "label" $theVariable.label -}}
    {{- if eq $theVariable.type "query" -}}
      {{- $_ := set $theListSpec "datasource" $lokiDatasource -}}
      {{- $_ := set $theListSpec "refresh" 2 -}}
      {{- $_ := set $theListSpec "multi" true -}}
      {{- $_ := set $theListSpec "includeAll" true -}}
      {{- $query := dict "label" $theVariable.queryLabel -}}
      {{- $_ := set $query "type" 1 -}}
      {{- $_ := set $theListSpec "query" $query -}}
    {{- else if eq $theVariable.type "textbox" -}}
      {{- $_ := set $theListSpec "query" "" -}}
    {{- else -}}
      {{- fail "You must set a type in Grafana dashboard variables" -}}
    {{- end -}}

    {{- $variableSpecs = append $variableSpecs $theListSpec -}}
  {{- end -}}

  {{- $_ := set $logsDashboardJson "panels" $panels -}}
  {{- $_ := set $logsDashboardJson "templating" (dict "list" $variableSpecs) -}}
  {{- $_ := set $logsDashboardJson "refresh" "5s" -}}
  {{- $_ := set $logsDashboardJson "title" "Smile CDR Logs" -}}
  {{- $_ := set $logsDashboardJson "uid" "regerjrjh656" -}}
  {{- $_ := set $logsDashboardJson "version" 1 -}}
  {{- $defaultTimeRange := dict "from" "now-3h" "to" "now" -}}
  {{- $_ := set $logsDashboardJson "time" $defaultTimeRange -}}

  {{- $_ := set $logsDashboard "json" $logsDashboardJson -}}

  {{- $logsDashboard | toYaml -}}
{{- end -}}



{{- /* Match all Selector Labels using 'and' logic */ -}}
{{- /* Requires 2 dict objects.
    selectorLabels - dict of required labels to match
    resourceLabels - dict of resource labels
    If selectorLabels is empty, always match
    If resourceLabels is empty but selectorLabels is not, never match
    */ -}}
{{- define "sdhCommon.matchLabels" -}}
  {{- if or (not (hasKey . "selectorLabels")) (not (hasKey . "resourceLabels")) -}}
    {{- fail (printf "\nsdhCommon.matchLabels: You must provide a dict with `selectorLabels` and `resourceLabels` keys") -}}
  {{- end -}}
  {{- $selectorLabels := .selectorLabels -}}
  {{- $resourceLabels := .resourceLabels -}}
  {{- $match := false -}}
  {{- $unMatchedLabels := false -}}
  {{- $skipMatching := false -}}
  {{- if and $selectorLabels (not $resourceLabels) -}}
    {{- /* If we have selector labels, but no resource labels, we will not match this metric */ -}}
    {{- $skipMatching = true -}}
    {{- $match = false -}}
  {{- else if not $selectorLabels -}}
    {{- /* If we have no selector labels, we will skip matching and automatically match this metric */ -}}
    {{- $skipMatching = true -}}
    {{- $match = true -}}
  {{- else if gt (len $selectorLabels) (len $resourceLabels) -}}
    {{- /* If we have more selector labels than resource labels, we will skip matching and not match this metric as it's impossible to match */ -}}
    {{- $skipMatching = true -}}
    {{- $match = false -}}
  {{- end -}}
  {{- if not $skipMatching -}}
    {{- range $theSelectorLabelName, $theSelectorLabelValue := $selectorLabels -}}
      {{- $labelMatches := false -}}
      {{- range $theMetricLabelName, $theMetricLabelValue := $resourceLabels -}}
        {{- if and (eq $theSelectorLabelName $theMetricLabelName) (eq $theSelectorLabelValue $theMetricLabelValue) -}}
          {{- $labelMatches = true -}}
        {{- end -}}
      {{- end -}}
      {{- if not $labelMatches -}}
        {{- $unMatchedLabels = true -}}
      {{- end -}}
    {{- end -}}
    {{- /* Only set match to true if there are no unmatched labels. */ -}}
    {{- $match = ternary false true $unMatchedLabels -}}
  {{- end -}}
  {{- $match | toYaml -}}
{{- end -}}
