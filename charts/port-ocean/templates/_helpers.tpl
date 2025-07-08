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
Selector labels
*/}}
{{- define "port-ocean.selectorLabels" }}
app.kubernetes.io/name: {{ include "port-ocean.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "port-ocean.liveEvents.selectorLabels" }}
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
{{- printf "%s-config" $prefix }}
{{- end }}

{{- define "port-ocean.liveEvents.configMapName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-live-events-config" $prefix }}
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
{{- printf "%s-ingress" $prefix }}
{{- end }}

{{- define "port-ocean.liveEvents.ingressName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-live-events-ingress" $prefix }}
{{- end }}

{{/*
Get service name 
*/}}
{{- define "port-ocean.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-service" $prefix }}
{{- end }}

{{- define "port-ocean.liveEvents.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-live-events-service" $prefix }}
{{- end }}

{{/*
Get container name
*/}}
{{- define "port-ocean.containerName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-container" $prefix }}
{{- end }}

{{/*
Get deployment name
*/}}
{{- define "port-ocean.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-deployment" $prefix }}
{{- end }}

{{- define "port-ocean.liveEvents.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-live-events-deployment" $prefix }}
{{- end }}


{{/*
Get ServiceAccount name
*/}}
{{- define "port-ocean.serviceAccountName" -}}
{{- if not (.Values.podServiceAccount).name }}
{{- $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-sa" $prefix }}
{{- else }}
{{- printf "%s" .Values.podServiceAccount.name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get cron job name
*/}}
{{- define "port-ocean.cronJobName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-cron-job" $prefix }}
{{- end }}

{{/*
Get self signed cert secret name
*/}}
{{- define "port-ocean.selfSignedCertName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-cert" $prefix }}
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