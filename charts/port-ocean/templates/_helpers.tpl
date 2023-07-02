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
{{ include "port-ocean.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "port-ocean.selectorLabels" -}}
app.kubernetes.io/name: {{ include "port-ocean.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get ocean config.yaml value
*/}}
{{- define "port-ocean.getOceanConfigYamlValue" -}}
{{- if (kindIs "string" .) }}
{{- . }}
{{- else if eq .type "secret" }}
{{- printf "{{ from env %s }}" .key  }}
{{- else if eq .type "env" }}
{{- printf "{{ from env %s }}" .key  }}
{{- end }}
{{- end }}

{{/*
Get prefix of ocean resource metadata.name
*/}}
{{- define "port-ocean.metadataNamePrefix" -}}
{{- printf "ocean-%s-%s" .type .identifier }}
{{- end }}

{{/*
Get config map name per integration
*/}}
{{- define "port-ocean.configMapName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-config" $prefix }}
{{- end }}

{{/*
Get secret name per integration
*/}}
{{- define "port-ocean.secretName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-secret" $prefix }}
{{- end }}

{{/*
Get ingress name per integration
*/}}
{{- define "port-ocean.ingressName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-ingress" $prefix }}
{{- end }}

{{/*
Get service name per integration
*/}}
{{- define "port-ocean.serviceName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-service" $prefix }}
{{- end }}

{{/*
Get container name per integration
*/}}
{{- define "port-ocean.containerName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-container" $prefix }}
{{- end }}

{{/*
Get deployment name per integration
*/}}
{{- define "port-ocean.deploymentName" -}}
{{ $prefix:= include "port-ocean.metadataNamePrefix" . }}
{{- printf "%s-deployment" $prefix }}
{{- end }}

{{- define "port-ocean.secretValue" -}}
{{- if (kindIs "string" .) }}
{{- else if eq .type "secret" }}
{{- $formattedKey := printf "%s" .key | upper | replace "-" "_" }}
{{- $value := .value -}}
{{ $formattedKey | nindent 4 }}: {{ $value | b64enc }}
{{- end }}
{{- end }}