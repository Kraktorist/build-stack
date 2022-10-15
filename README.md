## Prerequisites

- yandex.cloud account 
- `yc cli` installed and configured
- `docker` installed
- `git` installed
- ssh key generated [doc](docs/ssh-keys-generating.md)
- server certificates for `*.ru-central1.internal` zone generated (mostly for nexus) [doc](docs/certificates-generating.md)
- initial Yandex.Cloud Infrastructure


### Create initial Yandex.Cloud Infrastructure

First of all we need to create a folder and a network with routing table and internet gateway in it.
Here is a script which will all the objects:
```
./docs/prerequisites.sh
```

### Set ansible group vars

Update `envs/*/group_vars/all/secrets.yaml` with the generated parameters

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
    -v $(pwd)/boutique/components:/boutique \
    -ti builder
```

## Network installation

Network spec:

```yaml
network: 
  # network which must exist before running
  name: instances
  # list of subnets to create
  subnets:
    dev-a:
      zone: ru-central1-a 
      subnets: [192.168.16.0/28]
    dev-b:
      zone: ru-central1-b 
      subnets: [192.168.32.0/28]
  # list of security groups to create
  # doesn't support port range or port list
  # doesn't support other protocols but udp and tcp
  # -1 means all the ports
  # 0.0.0.0/0 means any IP address
  security_groups:
    allow_all:
      ingress:
        - protocol: tcp
          ports: -1
          cidr: [0.0.0.0/0]
      egress:
        - protocol: tcp
          ports: -1
          cidr: [0.0.0.0/0]
```

## Security Groups

Required Ports:
  Gitlab:
  - 80
  - 443
  Nexus:
  - 8081
  - 9179
  - 9182
  k8s:
  - 80
  - 2379
  - 2380
  - 6443
  - 10250
  - 10257
  - 10259

## Hosts Installation

Hosts spec:

```yaml
hosts:
  bastion:
    name: bastion
    cpu: 2
    memory: 4096
    disk: 40
    subnet: platform-a
    public_ip: true
    security_groups: [allow_all]  
  gitlab11:
    name: gitlab11
    cpu: 4
    memory: 8192
    disk: 40
    subnet: platform-a
    public_ip: false
    security_groups: [gitlab, ssh, common, internet, access_to_nexus, ansible_runner]
  nexus11:
    name: nexus11
    cpu: 2
    memory: 4096
    disk: 40
    subnet: platform-a
    public_ip: false
    security_groups: [nexus, ssh, common, internet, access_to_nexus]
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
NEXUS_REPO="nexus11.ru-central1.internal:9179"
docker tag builder ${NEXUS_REPO}/infrastructure/builder
docker login ${NEXUS_REPO} && docker push ${NEXUS_REPO}/infrastructure/builder
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
helm upgrade --install prom prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
## add some custom k8s objects
```

monitoring spec:

```yaml
monitoring:
  enabled: true
  name: prom
  namespace: monitoring
  helm_values: monitoring/values.yaml
  k8s_manifests:
  - monitoring/k8s/manifest1.yml
  - monitoring/k8s/manifest2.yml
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

## Certificate creating

```
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout internal-zone.key -out internal-zone.crt -subj "/CN=ru-central1.internal" \
  -addext "subjectAltName=DNS:*.ru-central1.internal"
```

## K8S runner provisioning

1. Copy kubeconfig from artifacts to `KUBECONFIG` env variable related to the certain gitlab environment
2. Copy gitlab_runner_token to the `RUNNER_TOKEN` env variable as well
3. Provision runner

## Boutique deployment

```
helm -n sock upgrade --install sock-shop /home/kraktorist/repos/lab-terraform-ya/build/helm/boutique --values /home/kraktorist/repos/lab-terraform-ya/boutique/deploy/prod/values.yaml
```


**TODO**

Infra:
  - ALB https://cloud.yandex.ru/docs/security/domains/checklist
  - security groups port range support
  - vms with multiple disks

Apps:
- build jobs for all microservices
  - on commit build to staging
  - on tag build to release
- prod deploy job
- app monitoring
- anybadge

## Issues

1. Find a way to copy /boutique folder
2. gitalb: The deployment job is older than the previously succeeded deployment job
   https://gitlab.com/gitlab-org/gitlab/-/issues/212621

## Working now

- make deploy for boutique environments
- monitoring apps


for docker push https://gitlab.com/gitlab-org/gitlab-runner/-/issues/1842
check if it's mandatory to create 
KUBECONFIG=/home/kraktorist/Downloads/artifacts\ \(1\)/envs/dev/artifacts/admin.conf kubectl -n gitlab-runner create secret generic defaultcertificates --from-file=/home/kraktorist/repos/test/selfsigned.crt

kubectl 
  --namespace sock-shop \
    create secret docker-registry registry-creds \
  --docker-server=nexus11.ru-central1.internal:9182 \
  --docker-username= \
  --docker-password= \
  --docker-email=1@1.ru
