## Target

Build `microservices-demo` application on Yandex.Cloud infrastructure.

## Steps

- create infrastructure pipeline with `terraform` and `ansible`.
- deploy Yandex.Cloud Infrastructure (`gitlab`, `nexus`, `k8s`)
- create CI pipeline for all the microservices (`gitlab-ci`, `dind`, `kaniko`)
- create CD pipeline for environments (`gitlab-ci`, `helm`, `ansible`)
- Design and implement monitoring system (`prometheus-operator`, `helm`)

## Prerequisites

- yandex.cloud account 
- `yc cli` installed and configured
- `docker` installed
- `git` installed
- ssh key generated [details](docs/ssh-keys-generating.md)
- server certificates for `*.ru-central1.internal` zone generated (mostly for nexus) [details](docs/certificates-generating.md)

### Create initial Yandex.Cloud Infrastructure

First of all we need to create a cloud-folder and a network with routing table and internet gateway in it.
Here is a script which will provision all the objects:
```
./prerequisites.sh
```

This will return list of variables which need to be copied to ansible-vault secret file `envs/*/group_vars/all/secrets.yaml` and into the `build/builder.env` file


## Builder image

Contains ansible, kubectl and terraform.  
Location: [Dockerfile](builder/Dockerfile)  
Build Step: `docker build --no-cache ./builder/ -t builder`  
Run:  

```
docker run \
    --rm \
    --env-file builder/builder.env \
    -v $(pwd)/infrastructure:/app/infrastructure \
    -v $HOME/ya_key.pub:/root/ya_key.pub \
    -v $HOME/ya_key:/root/ya_key \
    -v $(pwd)/boutique/components:/boutique \
    -ti builder
```

## Запуск terraform:

```
export YC_CLOUD_ID=
export YC_FOLDER_ID=
export ACCESS_KEY=
export SECRET_KEY=
export API_KEY=
export S3_TF_STATE=

export YC_SERVICE_ACCOUNT_KEY_FILE=/app/key.json
export ENV=platform
export ENV_PATH=/app/infrastructure/envs/${ENV}
export TF_VAR_config=/app/infrastructure/envs/${ENV}/config.yml
export TF_VAR_ansible_inventory=/app/infrastructure/envs/${ENV}/inventory.yml
echo $API_KEY | base64 -d>key.json
export ANSIBLE_VAULT_PASSWORD=secured
export ANSIBLE_HOST_KEY_CHECKING="False"
echo $ANSIBLE_VAULT_PASSWORD>.vault
eval `ssh-agent -s`
ssh-add ~/ya_key
source /app/scripts/lib.sh

terraform_apply

```

# Provisioning

```
provision_bastion
# then set ANSIBLE_SSH_COMMON_ARGS variable to force all other task to use bastion host
export ANSIBLE_SSH_COMMON_ARGS='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@<BASTION_IP> -p 22322"'
provision_misc # this is apt-get update and certificates pushing
provision_gitlab
provision_nexus
provision_infra_repo
provision_infra_runner
provision_apps_repo
provision_k8s
```
# Infrastructure Pipeline

```yaml
stages:
  - plan
  - apply
  - prepare
  - provision
    - k8s
    - runner
    - monitoring
```

## Monitoring

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prom prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
## add some custom k8s objects
```

## Apps

Inject .gitlab-ci.yml

```
git filter-branch --index-filter "cp /home/kraktorist/repos/lab-terraform-ya/boutique/carts/.gitlab-ci.yml . && git add .gitlab-ci.yml" --tag-name-filter cat --prune-empty -- --all
# git push -m '[skip.ci]'
```

## K8S runner provisioning

1. Copy kubeconfig from artifacts to `KUBECONFIG` env variable related to the certain gitlab environment
2. Copy gitlab_runner_token to the `RUNNER_TOKEN` env variable as well
3. Provision runner

## Boutique deployment

```
helm -n sock upgrade --install sock-shop /home/kraktorist/repos/lab-terraform-ya/builder/helm/boutique --values /home/kraktorist/repos/lab-terraform-ya/boutique/deploy/prod/values.yaml
```


**TODO**

Infra:
  - ALB https://cloud.yandex.ru/docs/security/domains/checklist
  - security groups port range support
  - vms with multiple disks

## Issues

1. Find a way to copy /boutique folder

## Working now


infra:
- add handlers to ansible states
