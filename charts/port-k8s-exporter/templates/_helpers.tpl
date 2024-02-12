{{/*
Expand the name of the chart.
*/}}
{{- define "port-k8s-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "port-k8s-exporter.fullname" -}}
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
{{- define "port-k8s-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "port-k8s-exporter.labels" -}}
helm.sh/chart: {{ include "port-k8s-exporter.chart" . }}
{{ include "port-k8s-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $value := .Values.extraLabels }}
{{$key}}: {{ $value }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "port-k8s-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "port-k8s-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "port-k8s-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "port-k8s-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config map to use
*/}}
{{- define "port-k8s-exporter.configMapName" -}}
{{- default (include "port-k8s-exporter.fullname" .) .Values.configMap.name }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "port-k8s-exporter.secretName" -}}
{{- default (include "port-k8s-exporter.fullname" .) .Values.secret.name }}
{{- end }}

{{/*
Create the name of the cluster role to use
*/}}
{{- define "port-k8s-exporter.clusterRoleName" -}}
{{- default (include "port-k8s-exporter.fullname" .) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the cluster role binding to use
*/}}
{{- define "port-k8s-exporter.clusterRoleBindingName" -}}
{{- default (include "port-k8s-exporter.fullname" .) .Values.clusterRoleBinding.name }}
{{- end }}