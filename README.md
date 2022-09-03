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


## Build image

Contains ansible, kubectl and terraform. 
Location: [Dockerfile](build/Dockerfile)
Build Step: `docker build ./build/ -t build`

Запуск terraform:

```
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export YC_TOKEN=
export ENV=base # env for building

docker run \
    --entrypoint /bin/bash \
    -v $(pwd)/infra:/app/infra \
    -v $HOME/ya_key.pub:/root/ya_key.pub \
    -ti terraform
```
