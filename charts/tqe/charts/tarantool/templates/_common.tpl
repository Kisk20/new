{{/*
Return the proper image name
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "global" .Values.global ) }}
*/}}
{{- define "common.images.image" -}}
{{- $registryName := .imageRoot.registry | default ((.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}

{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

{{/*
Generate resources block if resources are defined
*/}}
{{- define "common.resources" -}}
{{- if and .resources (or .resources.requests .resources.limits) -}}
resources:
  {{- $requests := .resources.requests | default .resources.limits -}}
  {{- if or .resources.requests .resources.limits }}
  requests:
    {{- toYaml $requests | nindent 4 }}
  {{- end }}
  {{- if .resources.limits }}
  limits:
    {{- toYaml .resources.limits | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}