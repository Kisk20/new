# Helm-chart для Tarantool

Данный chart позволяет развернуть Tarantool-кластер с необходимым количеством компонентов реплик.
Конфигурация кластера хранится в etcd. 
Для развертывания последнего используется sub-chart от Bitnami.

Основные параметры конфигуации Tarantool-кластера находятся в values.yaml.
По-умолчанию развертывается следующая конфигурация:

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
```               

Tarantool Cluster Manager (TCM) предоставляет доступ к WEB UI кластера на порту 8081.

## Требования:

- Доступ к registry с образом Tarantool
- Доступ к docker.io для загрузки образа bitnami/etcd

## Установка:

```
# helm install helm-chart-tarantool
```

### Проброс порта для доступа к UI при использовании minikube на локальной машине

```
# kubectl port-forward %tcm-pod-name% 8081:8081
```

Данная команда пробросит порт 8081 пода %tcm-pod-name% на порт 8081 вашей машины. 
Web UI станет доступен по адресу http://localhost:8081.

### Проброс порта при запуске minuikube на виртуальной машине в облаке

Если вы запускаете minikube на виртуальной машине в облаке, то 
помимо описанного выше проброса порта из minikube, необходимо пробросить порт 
через ssh-туннель с виртуальной машины на вашу машину:

```
ssh -nNT -L 127.0.0.1:8081:127.0.0.1:8081 %username%@%IP%
```

Где %username% и %IP% - имя пользователя и адрес виртуальной машины с которой 
будет пробрасываться порт по ssh. Команда запускается на виртуальной машине. 
Web UI будет доступен на локальной машине по адресу http://localhost:8081.

### Создание secrets

Есть два варианта создания "секретов" - ручной и силами самого HELM-чарта
Для автоматического создания "секрета", необходимо раскомментировать параметр imageCredentials в values.yaml, а так же все его дочерние элементы. Затем необходимо присвоить дочерним элементам соответствующие значения. 
В поле imagePullSecrets необходимо указать имя секрета, которое будет соответствовать формуле: {{ .Release.name }}-secret, где вместо {{ .Release.name }}
подставляется имя релиза которое вы указали в параметрах команды helm install. 
Например 
```
helm install tarantool-test .
```
установит {{ .Release.name }} в значение tarantool-test, следовательно имя секрета, в данном случае, будет tarantool-test-secret
Далее секрет будет создан при выполнении команды helm install. 

Для создания "секрета" вручную, необходимо выполнить команду

```
kubectl create secret docker-registry %cred_name% --docker-server= --docker-username= --docker-password= --docker-email=
```
подставив после "=" соответствующие значения, а вместо %cred_name% имя секрета. Так же это имя нужно будет указать в values.yaml в imagePullSecrets.

# Конфигурация режима supervised failover

Для использования режима supervised failover нужно установить следующие параметры в values.yaml:

```
replication.failover: supervised
storage.replication.bootstrap_strategy: auto
```

# Использование переменных окружения через `values.yaml` и Kubernetes Secrets


---

### Вариант 1: Прямое указание переменных окружения через `values.yaml`

```yaml
env:
  DEBUG: "true"
  TEST_ENV: "4"
```

> В этом случае переменные будут встроены напрямую в шаблон как `env` блок.

---

### Вариант 2: Использование существующего Kubernetes Secret

```yaml
envSecretRef: tarantool-secrets
generateEnvSecret: false
```

> В этом варианте переменные окружения загружаются из уже существующего Secret `tarantool-secrets`.  
> Чарт **не будет создавать** Secret — он должен быть создан заранее вручную.  
> Параметр `envSecretData` можно указать только для справки (он не используется при установке).

---

### Вариант 3: Автоматическое создание Secret из значений `envSecretData`

```yaml
envSecretRef: tarantool-secrets
generateEnvSecret: true
envSecretData:
  TT_API_KEY: abc123
  TT_TOKEN: top-secret
```

> В этом случае Helm-чарт создаст Secret с именем `tarantool-secrets` и автоматически подключит его к контейнеру как `envFrom`.

---


