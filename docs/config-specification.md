- [Inventory Block](#inventory-block)
- [Hosts Block](#hosts-block)
- [Certificate Block](#certificate-block)
- [Balancer Block](#balancer-block)
- [Network Block](#network-block)
  - [Subnet Block](#subnet-block)
  - [Security Groups Block](#security-groups-block)
- [Runner Block](#runner-block)
- [Monitoring Block](#monitoring-block)
- [Example](#example)

## Inventory Block

It's just ansible inventory for kubespray and other hosts.

_Example_

```yaml
inventory:
  # ansible inventory structure
  # every host mentioned in this section must be specified in the hosts: section
  all:
    children:
      k8s_cluster:
        children:
          kube_node:
            hosts:
              master-dev13: 
          kube_control_plane:
            hosts:
              master-dev13: 
          etcd:
            hosts:
              master-dev13: 
```

## Hosts Block

Specification for all the hosts.

_Example_

```yaml
hosts:
  master-dev13:
    name: master-dev13
    cpu: 4
    memory: 8192
    disk: 40
    subnet: dev-a
    public_ip: false
    security_groups: [k8s_cluster]
```

- **`name`** - hostname  
- **`cpu`** - host CPU cores count  
- **`memory`** - memory size in Mb  
- **`disk`** - disk size in Gb (multiple disks not supported yet)  
- **`subnet`** - subnet which the machine should be connected  
- **`public_ip`** - boolean value if machine requires a public IP address (for bastion mostly)  
- **`security_groups`** - list of VPC Security Groups (according to Yandex Cloud documentation it's limited to 5)  

## Certificate Block

Specification for Let's Encrypt certificate created in Certificate Manager

_Example_

```yaml
certificate:
  name: env-debug
  wait_validation: true
  domains:
  - 'boutique.qamo.ru'
  - 'grafana.dev.qamo.ru'
  - 'grafana.prod.qamo.ru'
```

- **`name`** - certificate name
- **`wait_validation`** - wait for HTTP-01 challenge completed. Required for ALB installation.
- **`domains`** - list of domains (Subject Alternative Names). Wildcards are not supported as we don't use DNS-01 challenge.


## Balancer Block

Application Load Specification describes load balancer for the environment

_Example_

```yaml
balancer:
  target_port: 80
  ext_port: 80
  tls: true
  nodes:
  - master-dev13
```

- **`target_port`** - port on workers that ingress controller listens to
- **`ext_port`** - ALB port for user connections
- **`tls`** - boolean value to enable HTTPS (certificate block required)
- **`nodes`** - list of backend nodes

## Network Block

This block is for subnets and security group creation.

_Example_

```yaml
network: 
  name: instances
  subnets:
  # etc
  security_groups:
  # etc
```

- **`name`** - name of network. This network must exists.
- **`subnets`** - map of subnets to create
- **`security_groups`** - map of security groups to create

### Subnet Block

_Example_

```yaml
network: 
  name: instances
  subnets:
    dev-a:
      zone: ru-central1-a 
      subnets: [192.168.16.0/28]
```

- **`zone`** - availability zone where the subnet will be created 
- **`subnets`** - list of CIDR which the subnet will utilize.

###  Security Groups Block

_Example_

```yaml
network: 
  security_groups:
    k8s_cluster:
      ingress:
        - protocol: tcp
          ports: 1-65535
          cidr: [192.168.0.0/16]
      egress:
        - protocol: tcp
          ports: 1-65535
          cidr: [192.168.0.0/16]
```

Each security group must have at least one block `egress` or `ingress`. Such block contain list of rules with the following specification:

- **`protocol`** - IP protocol `TCP` or `UDP`
- **`ports`** - port number or port range. Example of valid values: "80", "1024-65535"
- **`cidr`** - list of CIDR to apply

## Runner Block

This block is for k8s gitlab-runner deployment. It describes helm values and namespace for this task

_Example_

```yaml
runner:
  enabled: true
  name: gitlab-runner
  namespace: gitlab-runner
  helm_values: 
    - runner/values.yml
```

- **`enabled`** - boolean value for installation  
- **`name`** - name of helm release  
- **`namespace`** - kubernetes namespace for installation. Default is `default`  
- **`helm_values`** - list of Values.yaml files  
- **`k8s_manifests`** - additional kubernetes manifests to deploy.  

## Monitoring Block

This block is for k8s monitoring deployment. It describes helm values and namespace for this task.

_Example_

```yaml
monitoring:
  enabled: true
  name: prometheus
  namespace: monitoring
  helm_values: 
    - monitoring/values.yaml
  k8s_manifests:
  - monitoring/k8s/dashboards.yml
```

- **`enabled`** - boolean value for installation
- **`name`** - name of helm release
- **`namespace`** - kubernetes namespace for installation. Default is `gitlab-runner`
- **`helm_values`** - list of Values.yaml files 

## Example

```yaml
inventory:
  # ansible inventory structure
  # every host mentioned in this section must be specified in the params: section
  all:
    children:
      k8s_cluster:
        children:
          kube_node:
            hosts:
              master-dev13: 
          kube_control_plane:
            hosts:
              master-dev13: 
          etcd:
            hosts:
              master-dev13: 
  
# monitoring spec
monitoring:
  enabled: true
  name: prometheus
  namespace: monitoring
  helm_values: 
    - monitoring/values.yaml
  k8s_manifests:
  - monitoring/k8s/dashboards.yml


# gitlab runner spec
runner:
  enabled: true
  name: gitlab-runner
  namespace: gitlab-runner
  helm_values: 
    - runner/values.yml

# network spec
network: 
  name: instances
  subnets:
    dev-a:
      zone: ru-central1-a 
      subnets: [192.168.16.0/28]
  security_groups:
    k8s_cluster:
      ingress:
        - protocol: tcp
          ports: 1-65535
          cidr: [192.168.0.0/16]
        - protocol: udp
          ports: 1-65535
          cidr: [192.168.0.0/16]
      egress:
        - protocol: tcp
          ports: 1-65535
          cidr: [192.168.0.0/16]
        - protocol: udp
          ports: 1-65535
          cidr: [192.168.0.0/16]

hosts:
  master-dev13:
    name: master-dev13
    cpu: 4
    memory: 8192
    disk: 40
    subnet: dev-a
    public_ip: false
    security_groups: [k8s_cluster]

certificate:
  name: env-debug
  wait_validation: true
  domains:
  - 'boutique.qamo.ru'
  - 'grafana.dev.qamo.ru'
  - 'grafana.prod.qamo.ru'

balancer:
  target_port: 80
  ext_port: 80
  tls: true
  nodes:
  - master-dev13
```

