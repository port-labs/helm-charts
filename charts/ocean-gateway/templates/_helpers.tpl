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
ServiceAccount name for gateway pods.
*/}}
{{- define "ocean-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "ocean-gateway.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{/*
Resolved container image (repository:tag, tag defaults to latest).
*/}}
{{- define "ocean-gateway.image" -}}
{{- $tag := .Values.image.tag | default "latest" }}
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
Fail fast on incompatible Redis value combinations.
*/}}
{{- define "ocean-gateway.validateValues" -}}
{{- if and .Values.redis.enabled .Values.redis.existingSecret -}}
{{- fail "redis.enabled and redis.existingSecret are mutually exclusive" -}}
{{- end -}}
{{- if and .Values.redis.enabled (ne .Values.redis.url "") -}}
{{- fail "redis.url must not be set when redis.enabled=true" -}}
{{- end -}}
{{- if and .Values.redis.enabled (ne .Values.redis.password "") -}}
{{- fail "redis.password must not be set when redis.enabled=true; use redis.auth.password" -}}
{{- end -}}
{{- if and .Values.redis.enabled (ne .Values.redis.username "") -}}
{{- fail "redis.username must not be set when redis.enabled=true" -}}
{{- end -}}
{{- if and .Values.redis.enabled .Values.redis.tls.enabled -}}
{{- fail "redis.tls.enabled must not be set when redis.enabled=true" -}}
{{- end -}}
{{- if and .Values.redis.existingSecret (ne .Values.redis.url "") -}}
{{- fail "redis.url must not be set when redis.existingSecret is set" -}}
{{- end -}}
{{- if and .Values.redis.existingSecret (ne .Values.redis.password "") -}}
{{- fail "redis.password must not be set when redis.existingSecret is set" -}}
{{- end -}}
{{- if and .Values.redis.existingSecret (ne .Values.redis.username "") -}}
{{- fail "redis.username must not be set when redis.existingSecret is set" -}}
{{- end -}}
{{- if and .Values.redis.existingSecret .Values.redis.tls.enabled -}}
{{- fail "redis.tls.enabled must not be set when redis.existingSecret is set" -}}
{{- end -}}
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
Checksum for Redis credentials — changes trigger a rolling pod restart.
*/}}
{{- define "ocean-gateway.redisCredentialsChecksum" -}}
{{- if eq (include "ocean-gateway.redisSecretCreate" .) "true" -}}
{{- include (print $.Template.BasePath "/secret.yaml") . | sha256sum -}}
{{- else if .Values.redis.existingSecret -}}
{{- printf "%s|%s" .Values.redis.existingSecret (.Values.redis.credentialsRevision | default "") | sha256sum -}}
{{- end -}}
{{- end }}

{{/*
Image used by the wait-for-redis init container.
*/}}
{{- define "ocean-gateway.redisWaitImage" -}}
{{- $registry := .Values.redis.image.registry | default "docker.io" -}}
{{- $repository := .Values.redis.image.repository | default "bitnamisecure/redis" -}}
{{- $tag := .Values.redis.image.tag | default "latest" -}}
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
