{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "azure-workload-identity-webhook-bundle.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "azure-workload-identity-webhook-bundle.fullname" -}}
{{- $name := .Chart.Name -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "azure-workload-identity-webhook-bundle.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Resolve clusterID: use .Values.clusterID if set, otherwise derive from
the release name by stripping known chart name suffixes.
*/}}
{{- define "azure-workload-identity-webhook-bundle.clusterID" -}}
{{- if .Values.clusterID -}}
  {{- .Values.clusterID -}}
{{- else -}}
  {{- $name := .Release.Name -}}
  {{- range $suffix := list (printf "-%s" $.Chart.Name) "-azure-workload-identity-webhook-bundle" -}}
    {{- $name = trimSuffix $suffix $name -}}
  {{- end -}}
  {{- if eq $name .Release.Name -}}
    {{- fail "clusterID not set and cannot derive cluster name from release name" -}}
  {{- end -}}
  {{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "azure-workload-identity-webhook-bundle.labels" -}}
app.kubernetes.io/name: {{ include "azure-workload-identity-webhook-bundle.name" . }}
helm.sh/chart: {{ include "azure-workload-identity-webhook-bundle.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
giantswarm.io/service-type: "managed"
application.giantswarm.io/team: {{ index .Chart.Annotations "application.giantswarm.io/team" | quote }}
giantswarm.io/cluster: {{ include "azure-workload-identity-webhook-bundle.clusterID" . | quote }}
{{- end -}}

{{/*
Reusable: combine GS split registry+repository into upstream single repository.
*/}}
{{- define "giantswarm.combineImage" -}}
{{- $result := deepCopy . -}}
{{- $_ := set $result "repository" (printf "%s/%s" .registry .repository) -}}
{{- $_ := unset $result "registry" -}}
{{- $result | toYaml -}}
{{- end -}}

{{/*
Transform flat bundle values into the nested workload chart structure.
*/}}
{{- define "giantswarm.workloadValues" -}}
{{- $upstreamValues := dict -}}

{{/* Keys that belong to the bundle chart itself (never forwarded) */}}
{{- $bundleOnlyKeys := list "ociRepositoryUrl" "clusterID" "clusterName" -}}
{{/* Keys forwarded as workload extras (not under upstream:) */}}
{{- $extrasKeys := list "networkPolicy" "verticalPodAutoscaler" "global" -}}
{{/* Keys with special handling */}}
{{- $specialKeys := list "image" -}}
{{- $reservedKeys := concat $bundleOnlyKeys $extrasKeys $specialKeys -}}

{{/* Image: combine GS split format */}}
{{- $_ := set $upstreamValues "image" (include "giantswarm.combineImage" .Values.image | fromYaml) -}}

{{/* Preserve the original chart name for selector compatibility */}}
{{- $_ := set $upstreamValues "nameOverride" "azure-workload-identity-webhook" -}}

{{/* Pass through any non-reserved value to upstream */}}
{{- range $key, $val := .Values -}}
  {{- if not (has $key $reservedKeys) -}}
  {{- $_ := set $upstreamValues $key $val -}}
  {{- end -}}
{{- end -}}

{{/* Assemble workload values: upstream + extras */}}
{{- $workloadValues := dict "upstream" $upstreamValues -}}
{{- $_ := set $workloadValues "networkPolicy" .Values.networkPolicy -}}
{{- $_ := set $workloadValues "verticalPodAutoscaler" .Values.verticalPodAutoscaler -}}
{{- $_ := set $workloadValues "global" .Values.global -}}

{{- $workloadValues | toYaml -}}
{{- end -}}
