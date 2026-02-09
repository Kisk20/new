{{/*
Expand the name of the chart.
*/}}
{{- define "tarantool-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tarantool-chart.fullname" -}}
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
{{- define "tarantool-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tarantool-chart.labels" -}}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
{{ include "tarantool-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Return the proper imagePullSecrets value for Tarantool images
*/}}
{{- define "tarantool-chart.imagePullSecrets" -}}
{{ include "common.images.renderPullSecrets" (dict "images" (list .Values.image .Values.autoBootstrap.image) "context" $) }}
{{- if and .Values.imageCredentials (or (not (empty .Values.global.imagePullSecrets)) (not (empty .Values.image.pullSecrets))) }}
  - name: {{ .Release.Name }}-secret
{{- else -}}
  {{- if .Values.imageCredentials -}}
imagePullSecrets:
  - name: {{ .Release.Name }}-secret
  {{- end -}}
{{- end }}
{{- end -}}

{{/*
Return the proper imagePullPolicy value for Tarantool images
*/}}
{{- define "tarantool-chart.pullPolicy" -}}
{{- $pullPolicy := .Values.image.pullPolicy | default ((.Values.global).imagePullPolicy) -}}
{{- if $pullPolicy }}
    {{- printf "%s" $pullPolicy }}
{{- end -}}
{{- end -}}

{{/*
Return the proper imagePullPolicy value for autoBootstrap image
*/}}
{{- define "autoBootstrap.pullPolicy" -}}
{{- $pullPolicy := .Values.autoBootstrap.image.pullPolicy | default ((.Values.global).imagePullPolicy) -}}
{{- if $pullPolicy }}
    {{- printf "%s" $pullPolicy }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Tarantool image name
*/}}
{{- define "tarantool-chart.image" -}}
{{ include "common.images.image" ( dict "imageRoot" .Values.image "global" .Values.global ) }}
{{- end -}}

{{/*
Return the proper ETCD image name
*/}}
{{- define "etcd-chart.image" -}}
{{ include "common.images.image" ( dict "imageRoot" .Values.etcd.image "global" .Values.global ) }}
{{- end -}}

{{/*
Return the proper image for autobootstrap job
*/}}
{{- define "autoBootstrap.image" -}}
{{ include "common.images.image" ( dict "imageRoot" .Values.autoBootstrap.image "global" .Values.global ) }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "tarantool-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tarantool-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "tarantool-chart.templateLabels" -}}
{{- if . -}}
{{ toYaml . }}
{{- end -}}
{{- end -}}

{{- define "tarantool-chart.matchLabels" -}}
{{- if . -}}
{{ toYaml . }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "tarantool-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tarantool-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
{{/*
  Convert arbitrary .Values.env map to container env entries.
*/}}
{{- define "tarantool-chart.renderEnvVars" -}}
{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{/*
  Render envFrom.secretRef if a secret should be used as source of env vars.
  Works both for manually specified and generated secrets.
*/}}
{{- define "tarantool-chart.renderEnvFromSecret" -}}
{{- if or .Values.envSecretRef .Values.generateEnvSecret }}
envFrom:
  - secretRef:
      name: {{ default (printf "%s-env" .Release.Name) .Values.envSecretRef }}
{{- end }}
{{- end }}

{{/*
  Render the full config.yml block:
*/}}
{{- define "tarantool-chart.renderFullConfig" -}}

{{- /* корень конфигурации: либо .Values.config.parameters, либо .Values.config */ -}}
{{- $cfgRoot := ternary .Values.config.parameters .Values.config (hasKey .Values.config "parameters") -}}

{{- $contextDefault := dict "admin_password" (dict "from" "env" "env" "TT_ADMIN_PASSWORD") }}
{{- $iprotoDefault := dict "advertise" (dict
    "peer" (dict "login" "admin")
    "sharding" (dict "login" "admin")
) }}
{{- $replicationDefault := dict "failover" .Values.replication.failover }}

{{- $adminUser := dict "admin" (dict
    "password" "'{{ context.admin_password }}'"
    "roles" (list "super" "sharding" "replication")
    "privileges" (list (dict "permissions" (list "execute") "lua_call" (list "failover.execute")))
) }}

{{- $clientUser := dict .Values.credentials.clientUser.name (dict
    "password" .Values.credentials.clientUser.password
    "roles" (default list .Values.credentials.clientUser.roles)
) }}

{{- /* кастомные пользователи берём из корня ($cfgRoot), а не из .Values.config */ -}}
{{- $customUsers := default dict (get (default dict (get $cfgRoot "credentials")) "users") }}
{{- $allUsers := mustMergeOverwrite (mustMergeOverwrite $adminUser $clientUser) $customUsers }}

{{- $defaults := dict
  "config" (dict "context" $contextDefault)
  "iproto" $iprotoDefault
  "credentials" (dict "users" $allUsers)
  "replication" $replicationDefault
}}

{{- /* вместо deepCopy .Values.config → deepCopy $cfgRoot */ -}}
{{- $merged := deepCopy $cfgRoot }}
{{- range $key, $def := $defaults }}
  {{- $user := default dict (get $merged $key) }}
  {{- $_ := set $merged $key (mustMergeOverwrite $def $user) }}
{{- end }}

{{- $_ := unset $merged "groups" }}
{{- $_ := unset $merged "roles_cfg" }}

{{- range $key, $val := $merged }}
  {{- if $val }}
{{ $key }}:
{{- toYaml $val | nindent 2 }}
  {{- end }}
{{- end }}

{{- end }}

{{/*
  Render 'roles' section if there are any roles or metrics_export is enabled.
*/}}
{{- define "tarantool-chart.renderRolesSection" -}}
  {{- $roles := .roles | default (list) }}
  {{- $metrics := .metricsEnabled }}
  {{- $export := "roles.metrics-export" }}
  {{- $all := $roles }}
  {{- if and $metrics (not (has $export $roles)) }}
    {{- $all = append $all $export }}
  {{- end }}
  {{- if $all }}
roles:
{{- toYaml $all | nindent 2 }}
  {{- end }}
{{- end }}

{{/*
  Render the roles_cfg section.
*/}}
{{- define "tarantool-chart.renderRolesCfgSection" -}}
  {{- /* корень конфигурации: либо .Values.config.parameters, либо .Values.config */ -}}
  {{- $cfgRoot := ternary .Values.config.parameters .Values.config (hasKey .Values.config "parameters") -}}
  {{- $userCfg := get $cfgRoot "roles_cfg" | default dict }}
  {{- $rolesCfg := deepCopy $userCfg }}

  {{- $metrics := .Values.metrics_export }}
  {{- $exportRole := "roles.metrics-export" }}
  {{- $metricsEnabled := $metrics.enabled }}

  {{- $needAddMetrics := and $metricsEnabled (not (hasKey $rolesCfg $exportRole)) }}
  {{- if $needAddMetrics }}
    {{- $endpoint := dict
      "format" $metrics.http.endpoints.format
      "path" $metrics.http.endpoints.path
    }}
    {{- $metricsHttp := dict
      "http" (list (dict
        "listen" ($metrics.http.listen | int)
        "endpoints" (list $endpoint)
      ))
    }}
    {{- $_ := set $rolesCfg $exportRole $metricsHttp }}
  {{- end }}

  {{- if $rolesCfg }}
roles_cfg:
{{- toYaml $rolesCfg | nindent 2 }}
  {{- end }}
{{- end }}
