{{/*
Expand the name of the chart.
*/}}
{{- define "ocean-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec).
*/}}
{{- define "ocean-gateway.fullname" -}}
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
{{- define "ocean-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "ocean-gateway.labels" -}}
helm.sh/chart: {{ include "ocean-gateway.chart" . }}
{{ include "ocean-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels — used in matchLabels and service selectors.
*/}}
{{- define "ocean-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ocean-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolved container image (repository:tag, tag defaults to appVersion).
*/}}
{{- define "ocean-gateway.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
ConfigMap name.
*/}}
{{- define "ocean-gateway.configMapName" -}}
{{- printf "%s-config" (include "ocean-gateway.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret name (only created when redis.password is set).
*/}}
{{- define "ocean-gateway.secretName" -}}
{{- printf "%s-secret" (include "ocean-gateway.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Bundled Redis master service hostname (Bitnami standalone).
*/}}
{{- define "ocean-gateway.redisHost" -}}
{{- printf "%s-redis-master" .Release.Name }}
{{- end }}

{{/*
Redis URL for the gateway connection.
*/}}
{{- define "ocean-gateway.redisUrl" -}}
{{- if .Values.redis.enabled -}}
{{- printf "%s:6379" (include "ocean-gateway.redisHost" .) -}}
{{- else -}}
{{- required "redis.url is required when redis.enabled is false and redis.existingSecret is not set" .Values.redis.url -}}
{{- end -}}
{{- end }}

{{/*
Redis password for the gateway connection.
*/}}
{{- define "ocean-gateway.redisPassword" -}}
{{- if .Values.redis.enabled -}}
{{- .Values.redis.auth.password -}}
{{- else -}}
{{- .Values.redis.password -}}
{{- end -}}
{{- end }}

{{/*
Whether the chart should create a gateway Redis Secret.
*/}}
{{- define "ocean-gateway.redisSecretCreate" -}}
{{- if .Values.redis.existingSecret -}}
false
{{- else if .Values.redis.username -}}
true
{{- else if and .Values.redis.enabled .Values.redis.auth.enabled .Values.redis.auth.password -}}
true
{{- else if and (not .Values.redis.enabled) .Values.redis.password -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
Image used by the wait-for-redis init container.
*/}}
{{- define "ocean-gateway.redisWaitImage" -}}
{{- $registry := .Values.redis.image.registry | default "docker.io" -}}
{{- $repository := .Values.redis.image.repository | default "bitnami/redis" -}}
{{- $tag := .Values.redis.image.tag | default "7.4.3-debian-12-r0" -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end }}

{{/*
Ingress name.
*/}}
{{- define "ocean-gateway.ingressName" -}}
{{- printf "%s-ingress" (include "ocean-gateway.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Public webhook base URL when Ingress is enabled (scheme + host).
*/}}
{{- define "ocean-gateway.publicBaseUrl" -}}
{{- if .Values.ingress.tls -}}
https://{{ required "ingress.host is required when ingress is enabled" .Values.ingress.host }}
{{- else -}}
http://{{ required "ingress.host is required when ingress is enabled" .Values.ingress.host }}
{{- end -}}
{{- end }}
