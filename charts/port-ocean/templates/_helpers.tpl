{{/*
Expand the name of the chart.
*/}}
{{- define "port-ocean.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "port-ocean.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "port-ocean.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "port-ocean.labels" -}}
helm.sh/chart: {{ include "port-ocean.chart" . }}
{{- include "port-ocean.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{$key}}: {{ $value }}
{{- end }}
{{- end }}

{{/*
Live Events labels
*/}}
{{- define "port-ocean.liveEvents.labels" -}}
helm.sh/chart: {{ include "port-ocean.chart" . }}
{{- if .Values.liveEvents.worker.enabled -}}
{{- include "port-ocean.liveEvents.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{$key}}: {{ $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Actions Processor labels
*/}}
{{- define "port-ocean.actionsProcessor.labels" -}}
helm.sh/chart: {{ include "port-ocean.chart" . }}
{{- if .Values.actionsProcessor.worker.enabled -}}
{{- include "port-ocean.actionsProcessor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{$key}}: {{ $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "port-ocean.selectorLabels" }}
app.kubernetes.io/name: {{ include "port-ocean.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "port-ocean.liveEvents.selectorLabels" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "port-ocean.actionsProcessor.selectorLabels" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get prefix of ocean resource metadata.name
*/}}
{{- define "port-ocean.metadataNamePrefix" -}}
{{- if .Values.metadataNamePrefixOverride }}
{{- printf "%s" .Values.metadataNamePrefixOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "ocean-%s-%s" .Values.integration.type .Values.integration.identifier | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "port-ocean.metadataNamePrefixShort" -}}
{{- if .Values.metadataNamePrefixOverride }}
{{- printf "%s" .Values.metadataNamePrefixOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Values.integration.type .Values.integration.identifier | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get config map name 
*/}}
{{- define "port-ocean.configMapName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-config" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.liveEvents.configMapName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-le-config" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.actionsProcessor.configMapName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-ap-config" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get secret name 
*/}}
{{- define "port-ocean.secretName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- default (printf "%s-secret" $prefix) .Values.secret.name }}
{{- end }}

{{/*
Get ingress name 
*/}}
{{- define "port-ocean.ingressName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-ingress" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.liveEvents.ingressName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-le-ingress" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get service name 
*/}}
{{- define "port-ocean.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-service" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.liveEvents.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-le-service" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.actionsProcessor.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-ap-service" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get container name
*/}}
{{- define "port-ocean.containerName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-container" $prefix }}
{{- end }}

{{/*
Get default image
*/}}
{{- define "port-ocean.defaultImage" -}}
port-ocean-{{ .Values.integration.type }}:{{ .Values.integration.version | default "latest" }}
{{- end }}

{{/*
Get container image (registry + image name)
*/}}
{{- define "port-ocean.image" -}}
{{ .Values.imageRegistry }}/{{ .Values.image | default (include "port-ocean.defaultImage" .) }}
{{- end }}

{{/*
Get deployment name
*/}}
{{- define "port-ocean.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-deployment" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
resyncStaleCleanup CronJob name (Deployment workload only).
CronJob.metadata.name must be <= 52 characters (Kubernetes validation).
*/}}
{{- define "port-ocean.resyncStaleCleanupCronJobName" -}}
{{- $prefix := include "port-ocean.metadataNamePrefix" . -}}
{{- $jobName := printf "%s-resync-stale-cleanup" $prefix -}}
{{- if gt (len $jobName) 52 -}}
{{- /* len("-resync-stale-cleanup") == 21; CronJob name max 52 */ -}}
{{- $maxPrefixLen := int (sub 52 21) -}}
{{- $truncatedPrefix := trunc $maxPrefixLen $prefix | trimSuffix "-" -}}
{{- printf "%s-resync-stale-cleanup" $truncatedPrefix -}}
{{- else -}}
{{- $jobName -}}
{{- end -}}
{{- end }}

{{- define "port-ocean.liveEvents.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-le-deployment" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "port-ocean.actionsProcessor.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-ap-deployment" $prefix | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Get ServiceAccount name
*/}}
{{- define "port-ocean.serviceAccountName" -}}
{{- if not (.Values.podServiceAccount).name }}
{{- $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-sa" $prefix }}
{{- else }}
{{- printf "%s" (tpl .Values.podServiceAccount.name $) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get cron job name
Enforces Kubernetes CronJob name limit of 52 characters
*/}}
{{- define "port-ocean.cronJobName" -}}
{{- $prefix := include "port-ocean.metadataNamePrefix" . -}}
{{- $cronJobName := printf "%s-cron-job" $prefix -}}
{{- if gt (len $cronJobName) 52 -}}
{{- $maxPrefixLen := sub 52 9 -}}
{{- $truncatedPrefix := trunc $maxPrefixLen $prefix | trimSuffix "-" -}}
{{- printf "%s-cron-job" $truncatedPrefix -}}
{{- else -}}
{{- $cronJobName -}}
{{- end -}}
{{- end }}

{{/*
Get self signed cert secret name
*/}}
{{- define "port-ocean.selfSignedCertName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-cert" $prefix }}
{{- end }}

{{/*
Env vars for the main Ocean integration container (CronJob + Deployment): TLS bundle paths,
PostgreSQL connection when enabled, optional OCEAN__BASE_URL for live-events proxy mode,
and values.extraEnv (rendered with tpl).

Call with a dict:
  root: . (chart root context)
  includeLiveEventsBaseUrl: bool — true for main Deployment (proxy to liveEvents.baseUrl); false for CronJob

Outputs YAML `{ items: [ ... ] }` (items may be empty). Use with `fromYaml` then `.items`.
*/}}
{{- define "port-ocean.oceanMainContainerEnvList" -}}
{{- $root := .root }}
{{- $includeLiveEvents := index . "includeLiveEventsBaseUrl" | default false }}
{{- $items := list }}
{{- if $root.Values.selfSignedCertificate.enabled }}
{{- $items = concat $items (list
  (dict "name" "SSL_CERT_FILE" "value" "/etc/ssl/certs/ca-certificates.crt")
  (dict "name" "REQUESTS_CA_BUNDLE" "value" "/etc/ssl/certs/ca-certificates.crt")
) }}
{{- end }}
{{- if $root.Values.postgresql.enabled }}
{{- $items = concat $items (list
  (dict "name" "OCEAN__DATABASE__HOST" "value" (printf "%s-postgresql" (include "port-ocean.name" $root)))
  (dict "name" "OCEAN__DATABASE__PORT" "value" "5432")
  (dict "name" "OCEAN__DATABASE__NAME" "value" $root.Values.postgresql.global.postgresql.auth.database)
  (dict "name" "OCEAN__DATABASE__USERNAME" "value" $root.Values.postgresql.global.postgresql.auth.username)
  (dict "name" "OCEAN__DATABASE__PASSWORD" "value" $root.Values.postgresql.global.postgresql.auth.password)
) }}
{{- end }}
{{- if and $includeLiveEvents $root.Values.liveEvents.baseUrl (not $root.Values.liveEvents.worker.enabled) }}
{{- $items = append $items (dict "name" "OCEAN__BASE_URL" "value" $root.Values.liveEvents.baseUrl) }}
{{- end }}
{{- if $root.Values.extraEnv }}
{{- $extra := tpl (toYaml $root.Values.extraEnv) $root | fromYaml }}
{{- $items = concat $items $extra }}
{{- end }}
{{- dict "items" $items | toYaml }}
{{- end }}

{{- define "port-ocean.additionalSecrets" }}
{{- $secretsArray := list }}
{{- if or .Values.secret.create .Values.secret.name }}
  {{- $secretsArray = list (include "port-ocean.secretName" .) }}
{{- end }}
{{- /* If the secretName is already an array we don't wrap it in an array */}}
{{- if kindIs "slice" .Values.secret.name }}
  {{- $secretsArray = .Values.secret.name }}
{{- end }}
{{- range $secretsArray }}
- secretRef:
    name: {{ . }}
{{- end }}
{{- end }}