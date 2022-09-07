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
Build Step: `docker build ./build/ -t build`
Run: 

```
docker run \
    --entrypoint /bin/bash \
    -v $(pwd)/infrastructure:/app/infrastructure \
    -v $HOME/ya_key.pub:/root/ya_key.pub \
    -v $HOME/ya_key:/root/ya_key \
    -ti terraform
```

Запуск terraform:

```
export YC_CLOUD_ID=
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export YC_TOKEN=
export ENV=init
export S3_TF_STATE=dn-terraform-states
export TF_VAR_config=/app/infrastructure/envs/${ENV}/hosts.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml

source scripts/lib.sh
terraform_apply network
terraform_apply hosts

```

# Ansible provisioning

```
export YC_CLOUD_ID=
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export YC_TOKEN=
export ENV=init
export S3_TF_STATE=dn-terraform-states
export TF_VAR_config=/app/infrastructure/envs/${ENV}/hosts.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml

ssh-agent bash
ssh-add ~/ya_key
source scripts/lib.sh
provision_gitlab
provision_nexus
```

 - устанавливает gitlab
 - устанавливает gitlab-runner
 - устанавливает nexus

# Repositories creating

структура репозиториев:
- infrastructure (local runner)
  - full repo
  - envs
- apps (k8s runner)
  - weaveworks
  - googleshop

```
export YC_CLOUD_ID=
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export YC_TOKEN=
export ENV=init
export S3_TF_STATE=dn-terraform-states
export TF_VAR_config=/app/infrastructure/envs/${ENV}/hosts.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml

ssh-agent bash
ssh-add ~/ya_key
source scripts/lib.sh
provision_repos
```

**TODO:** 
- добавить gitlab-ci.yaml
- собрать runner image и загрузить в nexus

envs/.gitlab-ci.yaml 

Stages:
  - status:
    - status:
      - network
      - hosts
  - build:
    - plan
      - network
      - hosts 
    - apply
      - network
      - hosts 
  - provision
      - hosts
  - destroy
    - destroy
      - network
      - hosts