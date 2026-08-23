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
{{$key}}: {{ $value | quote }}
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
{{$key}}: {{ $value | quote }}
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
{{$key}}: {{ $value | quote }}
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
{{- printf "%s" .Values.metadataNamePrefixOverride | trimSuffix "-" }}
{{- else }}
{{- printf "ocean-%s-%s" .Values.integration.type .Values.integration.identifier | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Build a bounded Kubernetes resource name from a prefix and suffix. A hash is
added only when the name exceeds its limit.
*/}}
{{- define "port-ocean.resourceNameFromPrefix" -}}
{{- $prefix := index . 0 | trimSuffix "-" -}}
{{- $suffix := index . 1 -}}
{{- $maxLength := 63 -}}
{{- if gt (len .) 2 -}}
{{- $maxLength = int (index . 2) -}}
{{- end -}}
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
Build a Kubernetes resource name from the Ocean integration identity.
*/}}
{{- define "port-ocean.resourceName" -}}
{{- $root := index . 0 -}}
{{- $suffix := index . 1 -}}
{{- $prefix := include "port-ocean.metadataNamePrefix" $root -}}
{{- if gt (len .) 2 -}}
{{- include "port-ocean.resourceNameFromPrefix" (list $prefix $suffix (index . 2)) -}}
{{- else -}}
{{- include "port-ocean.resourceNameFromPrefix" (list $prefix $suffix) -}}
{{- end -}}
{{- end }}

{{/*
Get config map name 
*/}}
{{- define "port-ocean.configMapName" -}}
{{- include "port-ocean.resourceName" (list . "-config") }}
{{- end }}

{{- define "port-ocean.liveEvents.configMapName" -}}
{{- include "port-ocean.resourceName" (list . "-le-config") }}
{{- end }}

{{- define "port-ocean.incrementalSync.configMapName" -}}
{{- include "port-ocean.resourceName" (list . "-incr-config") }}
{{- end }}

{{- define "port-ocean.incrementalSync.cronJobName" -}}
{{- include "port-ocean.resourceName" (list . "-incr-cron" 52) }}
{{- end }}

{{- define "port-ocean.incrementalSync.schedule" -}}
{{- (.Values.incrementalSync.interval | default "*/15 * * * *") | toString -}}
{{- end -}}

{{- define "port-ocean.actionsProcessor.configMapName" -}}
{{- include "port-ocean.resourceName" (list . "-ap-config") }}
{{- end }}

{{/*
Get secret name 
*/}}
{{- define "port-ocean.secretName" -}}
{{- default (include "port-ocean.resourceName" (list . "-secret")) .Values.secret.name }}
{{- end }}

{{/*
Get ingress name 
*/}}
{{- define "port-ocean.ingressName" -}}
{{- include "port-ocean.resourceName" (list . "-ingress") }}
{{- end }}

{{- define "port-ocean.liveEvents.ingressName" -}}
{{- include "port-ocean.resourceName" (list . "-le-ingress") }}
{{- end }}

{{/*
Get service name 
*/}}
{{- define "port-ocean.serviceName" -}}
{{- include "port-ocean.resourceName" (list . "-service") }}
{{- end }}

{{- define "port-ocean.liveEvents.serviceName" -}}
{{- include "port-ocean.resourceName" (list . "-le-service") }}
{{- end }}

{{- define "port-ocean.actionsProcessor.serviceName" -}}
{{- include "port-ocean.resourceName" (list . "-ap-service") }}
{{- end }}

{{/*
Get container name
*/}}
{{- define "port-ocean.containerName" -}}
{{- include "port-ocean.resourceName" (list . "-container") }}
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
{{- include "port-ocean.resourceName" (list . "-deployment") }}
{{- end }}

{{- define "port-ocean.liveEvents.deploymentName" -}}
{{- include "port-ocean.resourceName" (list . "-le-deployment") }}
{{- end }}

{{- define "port-ocean.actionsProcessor.deploymentName" -}}
{{- include "port-ocean.resourceName" (list . "-ap-deployment") }}
{{- end }}

{{/*
Get ServiceAccount name
*/}}
{{- define "port-ocean.serviceAccountName" -}}
{{- if not (.Values.podServiceAccount).name }}
{{- include "port-ocean.resourceName" (list . "-sa") }}
{{- else }}
{{- printf "%s" (tpl .Values.podServiceAccount.name $) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get cron job name
Enforces Kubernetes CronJob name limit of 52 characters
*/}}
{{- define "port-ocean.cronJobName" -}}
{{- include "port-ocean.resourceName" (list . "-cron-job" 52) }}
{{- end }}

{{/*
Get self signed cert secret name
*/}}
{{- define "port-ocean.selfSignedCertName" -}}
{{- include "port-ocean.resourceName" (list . "-cert") }}
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

{{/*
Default container settings for chart-managed init containers (pull policy, security context, resources).
*/}}
{{- define "port-ocean.initContainer.containerDefaults" -}}
imagePullPolicy: {{ .Values.imagePullPolicy }}
securityContext:
  {{- if .Values.containerSecurityContext }}
  {{- toYaml .Values.containerSecurityContext | nindent 2 }}
  {{- end }}
resources:
  {{- if .Values.resources }}
  {{- toYaml .Values.resources | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Non-sensitive OAuth settings shared by every identity propagation provider.
Takes (list "<ENV_NAME>" <provider values>); provider-specific keys are rendered by the caller.
*/}}
{{- define "port-ocean.identityPropagation.providerConfig" -}}
{{- $envName := index . 0 -}}
{{- $provider := index . 1 -}}
{{- with $provider.clientId }}
OCEAN__IDENTITY_PROPAGATION__OAUTH__{{ $envName }}__CLIENT_ID: {{ . | quote }}
{{- end }}
{{- with $provider.scopes }}
OCEAN__IDENTITY_PROPAGATION__OAUTH__{{ $envName }}__SCOPES: {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Sensitive OAuth settings shared by every identity propagation provider.
Takes (list "<ENV_NAME>" <provider values>).
*/}}
{{- define "port-ocean.identityPropagation.providerSecret" -}}
{{- $envName := index . 0 -}}
{{- $provider := index . 1 -}}
{{- with $provider.clientSecret }}
OCEAN__IDENTITY_PROPAGATION__OAUTH__{{ $envName }}__CLIENT_SECRET: {{ . | b64enc | quote }}
{{- end }}
{{- end }}
