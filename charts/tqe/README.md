![Version: 2.5.3](https://img.shields.io/badge/Version-2.5.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.5.3](https://img.shields.io/badge/AppVersion-2.5.3-informational?style=flat-square)

[![Latest Release](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/badges/release.svg)](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/releases)

# Helm Chart TQE

## Оглавление
1. [Описание](#описание)
2. [Зависимости](#зависимости)
    1. [Чарты](#чарты)
    2. [Внешние сервисы](#внешние-сервисы)
3. [Конфигурация](#конфигурация)
4. [Запуск](#запуск)
    1. [Порядок развертывания](#порядок-развёртывания)
5. [Известные неполадки](#известные-неполадки-и-возможные-решения)

## Описание

Данный чарт позволяет развернуть [Tarantool QE][1].

В файле `Chart.yaml` указаны две версии:
* version: версия helm-чарта
* appVersion: самая свежая версия TarantoolQE, запущенная в чарте до релиза.

В результате разворачивания со всеми подключёнными необходимыми
[зависимостями](#зависимости) мы получаем следующую инфраструктуру:

```
etcd:
    |
    |---etcd-0
    |---etcd-1
    |---etcd-2

tarantool:
    |
    |---replicaset-router-0
    |   |
    |   |---router-0
    |
    |---replicaset-storage-0
        |
        |---storage-0

tcm:
    |
    |---tcm

tqe:
    |
    |---tqe-api-publisher
    |---tqe-api-consumer
```

## Зависимости

  * [tarantool](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tarantool)

Для корректной работы TarantoolQE необходимо иметь подключение к [Tarantool][2].

Используемые чарты добавлены как подмодули git.
Для их скачивания необходимо обновить git submodules:

```bash
git submodule update --init --recursive --remote
```

## Конфигурация

Файл включает в себя конфигурацию как для tqe, так и для всех подчартов по схеме:
```
# конфиг для чарта tqe

tarantool:
  # конфиг для чарта tarantool

  etcd:
  # конфиг для чарта etcd
```

Обратите внимание, что поля, не указанные в пользовательском values.yaml, будут
взяты из внутренних файлов values.yaml. Таким образом, если не указать явным
образом docker image для чарта tarantool, контейнер запустится на основе образа,
указанного в charts/tarantool/values.yaml. Поля, существующие в
`charts/tarantool/values.yaml` в блоке `config`, но не существующие
в вашем конфиге, будут в него добавлены.

Пример рабочего файла values.yaml:

```
tqe:
  consumer:
    replicas: 1
  publisher:
    replicas: 1
credentials:
  user: client
  password: secret

affinity:
nodeSelector:
tolerations: []

# Если в этой секции указаны limits и/или requests, то их содержимое будет передано в чарт как есть
resources:
  limits:
    cpu: "1"
  requests:
    cpu: "1"

tarantool:
  affinity:
  nodeSelector:
  tolerations: []

  image:
    repository: registry.ps.tarantool.io/tarantool/message-queue-ee
    pullPolicy: Always
    tag: 2.0.0
    command: ["tarantool"]
  imagePullSecrets:
    - name: ps-registry-auth

  router:
    replicasetCount: 1
    replicaCount: 2
    servicePort: 3301
    appPort: 3301
    memoryLimit: 512Mi
    cpuLimit: 200m
  storage:
    replicasetCount: 1
    replicaCount: 1
    servicePort: 3301
    appPort: 3301
    memoryLimit: 512Mi
    cpuLimit: 200m
    replicas: 1
  # Common parameters for routers/storages
  ttConfigEtcdPrefix: "/tqe"
  ttConfigEtcdHttpRequestTimeout: 3
  # Parameters for Trantool Cluster Manager
  tcmServicePort: 8081
  tcmMemoryLimit: 512Mi
  tcmCpuLimit: 200m
  tcmServicePort: 8081

  etcd:
    enabled: true
    replicaCount: 3
    auth:
      rbac:
        create: false

  config:
    parameters:
      credentials:
        users:
          admin:
            password: 'secret-cluster-cookie'
            roles: [super]
          client:
            password: 'secret'
            roles: [super]
          replicator:
            password: 'secret'
            roles: [replication]
          storage:
            password: 'secret'
            roles: [sharding]
      iproto:
        advertise:
          peer:
            login: replicator
          sharding:
            login: storage
      roles_cfg:
        roles.metrics-export:
          http:
          - endpoints:
            - format: prometheus
              path: /metrics
            listen: 8081
      sharding:
        bucket_count: 30000
      groups:
        routers:
          replication:
            failover: manual
          sharding:
            roles:
              - router
          roles:
            - app.roles.api
        storages:
          replication:
            failover: election
          sharding:
            roles: [storage]
          roles:
            - app.roles.queue
  tcm:
    parameters:
      http:
        host: 0.0.0.0
        port: 8081

      storage:
        provider: etcd
        etcd:
          prefix: /tcm

      security:
        bootstrap-password: secret

      cluster:
        tt-command: tt

        initial-settings:
          clusters:
            - name: Tarantool DB Cluster
              id: 00000000-0000-0000-0000-000000000000
              storage-connection:
                provider: etcd
                etcd-connection:
                  prefix: /tcm
                  username: client
                  password: secret
              tarantool-connection:
                username: "admin"
                password: secret

nodePorts:
  - name: iproto
    protocol: TCP
    port: 3301
    targetPort: iproto
  - name: membership
    protocol: UDP
    port: 3301
    targetPort: membership

image:
  repository: registry.ps.tarantool.io/tarantool/message-queue-ee
  pullPolicy: Always
  tag: 2.0.0

imagePullSecrets:
  - name: ps-registry-auth
```

## Запуск

Для запуска чарта настройте values.yaml как указано в главе
[Конфигурация](#конфигурация) и запустите helm:

```bash
helm install <release name> <path to chart>
```

### Порядок развёртывания

1. Инстансы etcd
2. Задача config job. Запускается, когда получает минимальный ответ от инстансов
etcd, добавляет конфигурационный файл.
3. Инстансы tarantool и tcm. Запускаются, когда утилита etcdctl показывает, что
в инстанс etcd успешно добавлен конфигурационный файл.
4. TQE gRPC (publisher, consumer) и gRPC офсет. Запускается, когда сервисы
`<release name>-router` и `<release name>-storage` начинают отвечать.

## Известные неполадки

| Проблема | Логи | Решение |
|---|---|---|
| Инстансы router и storage застряли в статусе `Pending`, gRPC в статусе `CrashLoopBackOff` | - | Не создались PV и PVC, неверно указан storage class в values |
| Инстансы etcd застряли в статусе `Pending`, инстансы tarantool в статусе `CrashLoopBackOff` | - | Не создались PV и PVC. Либо неверно указан storage class, либо не удалились PVC с предыдущего запуска. |
| Инстансы router и storage находятся в статусе CrashLoopBackOff | - | Вероятно, неверно задана конфигурация tarantool. Некоторые элементы конфига tarantool могут добавляться в текущий конфиг. Проверьте, нет ли лишних полей в `charts/tqe/charts/tarantool/values.yaml` в блоке `config:` |

[1]: https://www.tarantool.io/ru/queue-enterprise/
[2]: https://www.tarantool.io/ru/product/enterprise/

## Values

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.imagePullSecrets | list[object] | `[]` | Image pull secrets. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/secret/) to authenticate to docker registry tarantool chart for Pods. You can leave it empty if your registry doesn't requires authentication. You can generate secret by yourself or let us do it with imageCredentials (see Common section). Example: [{"name": "secret-name"}]. |

### TQE Consumer

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| consumer.replicas | int | `1` | Consumer replicas |
| consumer.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"}}` | Parameters to assign resources. You can leave it empty. If no value is set for requests, the values from limits will be used. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) |
| consumer.matchLabels | object | `{}` | Custom labels for consumer pods, will be added to spec.selector.matchLabels. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| consumer.templateLabels | object | `{}` | Custom labels for consumer pods, will be added to spec.template.metadata.labels. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| consumer.consumerCapacity | int | `nil` | TQE Shards (storages) count to connect to the one TQE Consumer. Fill this parameter if you absolutely sure that your trafic lets you do this. |

### TQE Publisher

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| publisher.replicas | int | `1` | Publisher replicas |
| publisher.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"}}` | Parameters to assign resources. You can leave it empty. If no value is set for requests, the values from limits will be used. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) |
| publisher.matchLabels | object | `{}` | Custom labels for publisher pods, will be added to spec.selector.matchLabels. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| publisher.templateLabels | object | `{}` | Custom labels for publisher pods, will be added to spec.template.metadata.labels. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |

### TQE Images

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | `"message-queue-ee"` | Repository name |
| image.pullPolicy | string | `"Always"` | Pull policy. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| image.tag | string | `"2.5.3"` | Tag |
| image.pullSecrets | list[object] | `[]` | Pull Secrets. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/secret/) to authenticate to docker registry tarantool chart for Pods. You can leave it empty if your registry doesn't requires authentication. You can generate secret by yourself or let us do it with imageCredentials (see Common section). Example: [{"name": "secret-name"}]. |

### TQE Credentials

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| credentials.user | string | `"client"` | Username |
| credentials.password | string | `"secret"` | Password |

### TQE GRPC options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| grpcOptions | object | `{"reflection_enabled":true}` | Parameters to assign additional options to GRPC configs |

### TQE Pods Placement

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `nil` | Parameters to assign TQE pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) |
| nodeSelector | object | `nil` | Parameters to assign TQE pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) |
| tolerations | list | `[]` | Parameters to assign TQE pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |

### Tarantool core

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.affinity | object | `nil` | Parameters to assign pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) |
| tarantool.nodeSelector | object | `nil` | Parameters to assign pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) |
| tarantool.tolerations | object | `[]` | Parameters to assign pods to nodes. You can leave it empty. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) |
| tarantool.ttConfigEtcdPrefix | string | `"/tqe"` | Prefix for etcd were cluster data stored |
| tarantool.ttConfigEtcdHttpRequestTimeout | int | `3` | Timeout for etcd requests |
| tarantool.image.repository | string | `"message-queue-ee"` | Repository name |
| tarantool.image.pullPolicy | string | `"Always"` | Pull policy. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| tarantool.image.tag | string | `"2.5.3"` | Tag |
| tarantool.image.command | list | `["tarantool"]` | Command |
| tarantool.image.pullSecrets | list[object] | `[]` | Pull Secrets. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/secret/) to authenticate to docker registry tarantool chart for Pods. You can leave it empty if your registry doesn't requires authentication. You can generate secret by yourself or let us do it with imageCredentials (see Common section). Example: [{"name": "secret-name"}]. |
| tarantool.config.parameters.roles_cfg | object | `{}` | Roles configuration |
| tarantool.config.parameters.sharding | object | `{"bucket_count":30000}` | Sharding configuration |
| tarantool.config.parameters.groups | object | `{"routerGroupName":{"sharding":{"roles":["router"]}},"storageGroupName":{"sharding":{"roles":["storage"]}}}` | Groups configuration |

### Tarantool Router

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.router.enabled | bool | `true` | Enable/disable routers in Tarantool cluster |
| tarantool.router.routerGroupName | string | `"routers"` | Group name for routers in Tarantool cluster |
| tarantool.router.replicasetCount | int | `1` | Replicaset count for routers in Tarantool cluster |
| tarantool.router.replicaCount | int | `1` | Replica count for routers in Tarantool cluster |
| tarantool.router.servicePort | int | `3301` | Service port for routers in Tarantool cluster |
| tarantool.router.appPort | int | `3301` | App port for routers in Tarantool cluster |
| tarantool.router.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"}}` | Resources for routers in Tarantool cluster. If no value is set for requests, the values from limits will be used. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) |
| tarantool.router.roles | list | `["app.roles.api"]` | Roles for routers in Tarantool cluster. [Check tarantool docs for more information](https://www.tarantool.io/ru/doc/latest/platform/app/app_roles/#api-reference) |

### Tarantool Storage

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.storage.storageGroupName | string | `"storages"` | Group name for storages in Tarantool cluster |
| tarantool.storage.replicasetCount | int | `1` | Replicaset count for storages in Tarantool cluster |
| tarantool.storage.replicaCount | int | `1` | Replica count for storages in Tarantool cluster |
| tarantool.storage.servicePort | int | `3301` | Service port for storages in Tarantool cluster |
| tarantool.storage.appPort | int | `3301` | App port for storages in Tarantool cluster |
| tarantool.storage.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"}}` | Resources for storages in Tarantool cluster. If no value is set for requests, the values from limits will be used. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits) |
| tarantool.storage.persistence.storageClassName | string | `""` | Value of storage class name. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/storage/storage-classes/) |
| tarantool.storage.roles | list | `["app.roles.queue"]` | Roles for storages in Tarantool cluster. [Check tarantool docs for more information](https://www.tarantool.io/ru/doc/latest/platform/app/app_roles/#api-reference) |

### Tarantool autoBootstrap

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.autoBootstrap.enabled | bool | `true` | Enable/disable vshard bootstrap using tt tool |
| tarantool.autoBootstrap.maxAttempts | int | `6` | How many times the autobootstrap job should try bootstrapping vShard |
| tarantool.autoBootstrap.timeout | int | `30` | A timeout for tt tool when bootstrapping vShard, seconds |
| tarantool.autoBootstrap.image.registry | string | `""` | Registry name |
| tarantool.autoBootstrap.image.repository | string | `"tt"` | Repository/image name |
| tarantool.autoBootstrap.image.tag | string | `"2.10.0"` | Image's tag |
| tarantool.autoBootstrap.image.pullPolicy | string | `"IfNotPresent"` | Image's pull policy |
| tarantool.autoBootstrap.image.pullSecrets | list[object] | `[]` | Pull Secrets. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/configuration/secret/) to authenticate to docker registry tarantool chart for Pods. You can leave it empty if your registry doesn't requires authentication. You can generate secret by yourself or let us do it with imageCredentials (see Common section). Example: [{"name": "secret-name"}]. |

### Tarantool TCM

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.tcm.servicePort | int | `8081` | Service port for Trantool Cluster Manager |
| tarantool.tcm.resources | object | `{"limits":{"cpu":"50m","memory":"256Mi"}}` | Resources for Trantool Cluster Manager |
| tarantool.tcm.initial-settings.clusters[0] | object | `{"id":"00000000-0000-0000-0000-000000000000","name":"TQE Cluster","storage-connection":{"etcd-connection":{"prefix":"/tqe"},"provider":"etcd"},"tarantool-connection":{"password":"secret","username":"client"}}` | Name of the TQE cluster |
| tarantool.tcm.initial-settings.clusters[0].id | string | `"00000000-0000-0000-0000-000000000000"` | ID of the TQE cluster |
| tarantool.tcm.initial-settings.clusters[0].storage-connection.provider | string | `"etcd"` | Storage provider |
| tarantool.tcm.initial-settings.clusters[0].storage-connection.etcd-connection.prefix | string | `"/tqe"` | etcd connection prefix were cluster data stored |
| tarantool.tcm.initial-settings.clusters[0].tarantool-connection | object | `{"password":"secret","username":"client"}` | Tarantool connection settings |
| tarantool.tcm.initial-settings.clusters[0].tarantool-connection.username | string | `"client"` | Tarantool username |
| tarantool.tcm.initial-settings.clusters[0].tarantool-connection.password | string | `"secret"` | Tarantool password |

### etcd

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tarantool.etcd.enabled | bool | `true` | Enable/disable etcd |
| tarantool.etcd.replicaCount | int | `3` | Replica count for etcd |
| tarantool.etcd.persistence | object | `{"size":"512Mi","storageClass":""}` | Persistence settings for etcd |
| tarantool.etcd.persistence.storageClass | string | `""` | Storage class name. [Check K8s docs for more information](https://kubernetes.io/docs/concepts/storage/storage-classes/) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
