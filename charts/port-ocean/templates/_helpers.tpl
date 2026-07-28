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
{{- printf "%s" .Values.metadataNamePrefixOverride }}
{{- else }}
{{- printf "ocean-%s-%s" .Values.integration.type .Values.integration.identifier }}
{{- end }}
{{- end }}

{{/*
Build a Kubernetes resource name without losing the identity encoded in a long
integration identifier. A hash is added only when the name exceeds its limit.
*/}}
{{- define "port-ocean.resourceName" -}}
{{- $prefix := include "port-ocean.metadataNamePrefix" .root -}}
{{- $suffix := .suffix -}}
{{- $maxLength := int .maxLength -}}
{{- $name := printf "%s%s" $prefix $suffix -}}
{{- if gt (len $name) $maxLength -}}
{{- $hash := sha256sum $prefix | trunc 8 -}}
{{- $maxPrefixLen := int (sub $maxLength (add (len $suffix) 9)) -}}
{{- $truncatedPrefix := trunc $maxPrefixLen $prefix | trimSuffix "-" -}}
{{- printf "%s-%s%s" $truncatedPrefix $hash $suffix -}}
{{- else }}
{{- $name -}}
{{- end }}
{{- end }}

{{/*
Get config map name 
*/}}
{{- define "port-ocean.configMapName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-config" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.liveEvents.configMapName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-le-config" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.incrementalSync.configMapName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-incr-config" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.incrementalSync.cronJobName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-incr-cron" "maxLength" 52) }}
{{- end }}

{{- define "port-ocean.incrementalSync.schedule" -}}
{{- (.Values.incrementalSync.interval | default "*/15 * * * *") | toString -}}
{{- end -}}

{{- define "port-ocean.actionsProcessor.configMapName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-ap-config" "maxLength" 63) }}
{{- end }}

{{/*
Get secret name 
*/}}
{{- define "port-ocean.secretName" -}}
{{- default (include "port-ocean.resourceName" (dict "root" . "suffix" "-secret" "maxLength" 63)) .Values.secret.name }}
{{- end }}

{{/*
Get ingress name 
*/}}
{{- define "port-ocean.ingressName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-ingress" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.liveEvents.ingressName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-le-ingress" "maxLength" 63) }}
{{- end }}

{{/*
Get service name 
*/}}
{{- define "port-ocean.serviceName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-service" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.liveEvents.serviceName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-le-service" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.actionsProcessor.serviceName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-ap-service" "maxLength" 63) }}
{{- end }}

{{/*
Get container name
*/}}
{{- define "port-ocean.containerName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-container" "maxLength" 63) }}
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
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-deployment" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.liveEvents.deploymentName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-le-deployment" "maxLength" 63) }}
{{- end }}

{{- define "port-ocean.actionsProcessor.deploymentName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-ap-deployment" "maxLength" 63) }}
{{- end }}

{{/*
Get ServiceAccount name
*/}}
{{- define "port-ocean.serviceAccountName" -}}
{{- if not (.Values.podServiceAccount).name }}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-sa" "maxLength" 63) }}
{{- else }}
{{- printf "%s" (tpl .Values.podServiceAccount.name $) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get cron job name
Enforces Kubernetes CronJob name limit of 52 characters
*/}}
{{- define "port-ocean.cronJobName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-cron-job" "maxLength" 52) }}
{{- end }}

{{/*
Get self signed cert secret name
*/}}
{{- define "port-ocean.selfSignedCertName" -}}
{{- include "port-ocean.resourceName" (dict "root" . "suffix" "-cert" "maxLength" 63) }}
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