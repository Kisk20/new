{{- define "commonSelector" }}
  selector:
    matchLabels:
      app: {{ . }}
{{- end }}

{{- define "grpc-service-ports" }}
  - name: monitoring
    port: 18184
    targetPort: monitoring
    protocol: TCP
  - name: grpc
    port: 18182
    protocol: TCP
    targetPort: grpc
{{- end }}

{{- define "grpc-service-common-config" }}
    app_name: MESSAGE_QUEUE_EE_API
    app_version: test
    core_host: 0.0.0.0
    core_port: 18184
    grpc_host: 0.0.0.0
    grpc_port: 18182
    grpc_options:
    {{- if $.Values.grpcOptions }}
      {{- toYaml $.Values.grpcOptions | nindent 6 }}
    {{- end }}
{{- end }}

{{/*
  Convert arbitrary .Values.env map to container env entries.
*/}}
{{- define "tqe.renderEnvVars" -}}
{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/* Count how many shards gRPC can use */}}
{{- define "tqe.consumer-count" -}}
{{- if .consumer.consumerCapacity  -}}
{{- $a := divf .tarantool.storage.replicasetCount .consumer.consumerCapacity -}}
{{- ceil $a -}}
{{- else -}}
{{ .tarantool.storage.replicasetCount }}
{{- end }}
{{- end }}

{{/* Create list of the storage services gRPC consumer can connect */}}
{{- define "tqe.storages-list" -}}

{{- if .consumerCapacity -}}
{{- $indexStart := mul .consumerCapacity .consumerCurrentIndex | int -}}
{{- $indexEnd := min (add $indexStart .consumerCapacity) .storageReplicasets | int -}}
{{- range $storageReplicasetIndex := untilStep $indexStart $indexEnd 1 }}
          storage-{{ $storageReplicasetIndex }}:
{{- range $storageReplicaIndex := until $.storageReplicas }}
          - "{{ $.releaseName }}-replicaset-{{ $storageReplicasetIndex }}-storage-{{ $storageReplicaIndex }}.{{ $.releaseName }}-replicaset-{{ $storageReplicasetIndex }}-storage.{{ $.namespace }}.svc.cluster.local:3301"
{{- end -}}
{{- end -}}

{{- else -}}
          storage:
{{- range $storageReplicaIndex := until $.storageReplicas }}
          - {{ $.releaseName }}-replicaset-{{ $.consumerCurrentIndex }}-storage-{{ $storageReplicaIndex }}.{{ $.releaseName }}-replicaset-{{ $.consumerCurrentIndex }}-storage.{{ $.namespace }}.svc.cluster.local:3301"
{{- end -}}
{{- end -}}
{{- end -}}
