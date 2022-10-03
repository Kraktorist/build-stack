## Последовательность

1. Деплоим каркас сетей в терраформ
2. Устанавливаем машины
- gitlab
- nexus
3. Делаем provisioning
- gitlab
- gitlab-runner (linux)
- nexus
4. Деплоим репозитории
- инфраструктура
- приложение

5. Деплой кластера. Репозиторий инфраструктура по деплою в ветку infra/ создает джобу
  - установка хостов
  - провиженинг кластера
  - добавление раннера
  - провиженинг мониторинга (вручную)

6. Сборка приложений
По коммиту изменений в ветку develop/ создается джоба
  - сборка приложения в staging версию (версия - CI_PIPELINE_IID, CI_COMMIT_SHORT_SHA)
  - деплой приложения на dev кластер (вручную)

7. Релиз
По тэгу в в ветке мастер создается джоба
  - сборка приложения (версия = тэг)
  - деплой приложения на prod

Отсюда структура репозитория
- infrastructure
  - envs
    - base
    - dev
    - uat
    - prod
  - modules
    - terraform
    - ansible
- apps

## Prerequisites

- generated ssh-key
- yandex.cloud created account
- yandex.cloud created cloud YC_CLOUD_ID
- yandex.cloud created folder YC_FOLDER_ID
- yandex.cloud created service account and editor permissions
- yandex.cloud created ACCESS_KEY and SECRET_KEY
- yandex.cloud created s3 bucket S3_TF_STATE
- yandex.cloud created OAUTH token for s3 bucket access YC_TOKEN
- workstation with docker

## Build image

Contains ansible, kubectl and terraform.  
Location: [Dockerfile](build/Dockerfile)  
Build Step: `docker build --no-cache ./build/ -t builder`  
Run:  

```
docker run \
    --rm \
    --entrypoint /bin/bash \
    -v $(pwd)/infrastructure:/app/infrastructure \
    -v $HOME/ya_key.pub:/root/ya_key.pub \
    -v $HOME/ya_key:/root/ya_key \
    -v $(pwd)/boutique:/boutique \
    -ti builder
```

## Network installation

Network spec:

```yaml
network: 
  name: instances
  subnets:
    dev-a:
      zone: ru-central1-a 
      subnets: [192.168.16.0/28]
    dev-b:
      zone: ru-central1-b 
      subnets: [192.168.32.0/28]
```

## Hosts Installation

Hosts spec:

```yaml
hosts:
  gitlab11:
    name: gitlab11
    cpu: 2
    memory: 4096
    disk: 40
    subnet: platform-a
    public_ip: true
  nexus11:
    name: nexus11
    cpu: 2
    memory: 4096
    disk: 40
    subnet: platform-a
    public_ip: true
```

Inventory spec:

```yaml
inventory:
  # ansible inventory structure
  # every host mentioned in this section must be specified in the params: section
  all:
    children:
      # kupespray structure
      k8s_cluster:
        children:
          kube_node:
            hosts:
              worker-dev11:  
              worker-dev12:
          kube_control_plane:
            hosts:
              master-dev13: 
          etcd:
            hosts:
              master-dev13:
      # other hosts 
      gitlab:
        hosts:
          gitlab11:
      runner:
        hosts:
          gitlab11:
      nexus:
        hosts:
          nexus11:
```

Запуск terraform:

```
export YC_CLOUD_ID=
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export YC_TOKEN=
export ENV=platform
export S3_TF_STATE=dn-terraform-states
export TF_VAR_config=/app/infrastructure/envs/${ENV}/config.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml
export ENV_PATH=/app/infrastructure/envs/${ENV}

export ANSIBLE_VAULT_PASSWORD=
export ANSIBLE_HOST_KEY_CHECKING="False"
echo $ANSIBLE_VAULT_PASSWORD>.vault
eval `ssh-agent -s`
ssh-add ~/ya_key
source /app/scripts/lib.sh

terraform_apply network
terraform_apply hosts

```

# Provisioning

```
provision_misc # this is apt-get update
provision_gitlab
provision_nexus
provision_infra_repo
provision_infra_runner
provision_k8s
```

# Repositories creating

структура репозиториев:
- infrastructure (local runner)
  - full repo (for building builder image)
  - envs
- apps (k8s runner)
  - weaveworks
  - boutique

# Upload builder image

```
# add insecure registry
# sudo vi /etc/docker/daemon.json
# sudo systemcl restart docker
# nexus address
NEXUS_REPO="nexus:9080"
docker tag builder ${NEXUS_REPO}/infrastructure/builder
echo $NEXUS_PASS | docker login -u $NEXUS_USER --password-stdin ${NEXUS_REPO}
docker push ${NEXUS_REPO}/infrastructure/builder
```

# Infrastructure pipeline

Stages:
  - status:
    - network
    - hosts
  - plan
    - network
    - hosts 
  - apply
    - network
    - hosts 
  - provision
    - gitlab
    - nexus
    - runner
    - k8s
    - repo
    - monitoring
  - destroy
    - network
    - hosts

## Monitoring

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prom prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
```

monitoring spec:

```yaml
monitoring:
  enabled: true
  name: prom
  namespace: monitoring
  helm_values: monitoring/values.yaml
```

## Apps

Inject .gitlab-ci.yml

```
git filter-branch --index-filter "cp /home/kraktorist/repos/lab-terraform-ya/boutique/carts/.gitlab-ci.yml . && git add .gitlab-ci.yml" --tag-name-filter cat --prune-empty -- --all
# git push -m '[skip.ci]'
```

Get image from private registry

```
ctr i pull -u admin --plain-http 192.168.0.48:9080/boutique/carts:72567a7a
```

containerd config

```
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.6"
    max_container_log_line_size = -1
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      snapshotter = "overlayfs"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          runtime_engine = ""
          runtime_root = ""
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            systemdCgroup = true
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.0.48"]
          endpoint = ["http://192.168.0.48:9080"]
        [plugins."io.containerd.grpc.v1.cri".registry.configs]
          [plugins."io.containerd.grpc.v1.cri".registry.configs."test.http-registry.io".tls]
            insecure_skip_verify = true
```

## K8S runner provisioning

1. Copy kubeconfig from artifacts to `KUBECONFIG` env variable related to the certain gitlab environment
2. Copy gitlab_runner_token to the `RUNNER_TOKEN` env variable as well
3. Provision runner


**TODO**

Infra:
  - working through bastion host and ALB https://cloud.yandex.ru/docs/security/domains/checklist
  - security groups
  - ansible inventory as a separate step
  - vms with multiple disks
  - tls connections

Apps:
- build jobs for all microservices
  - on commit build to staging
  - on tag build to release
- prod deploy job
- app monitoring
- anybadge

## Working now

- deploy applications (make helm deployment)
- monitoring apps

## Issues

1. Find a way to copy /boutique folder
2. `catalogue` and `payment` don't work on privileged ports