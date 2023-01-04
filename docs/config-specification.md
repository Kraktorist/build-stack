
## Inventory Block

It's just ansible inventory for kubespray and other hosts.

## Hosts Block

Specification for all the hosts.

- **`name`** - hostname  
- **`cpu`** - host CPU cores count  
- **`memory`** - memory size in Mb  
- **`disk`** - disk size in Gb (multiple disks not supported yet)  
- **`subnet`** - subnet which the machine should be connected  
- **`public_ip`** - boolean value if machine requires a public IP address (for bastion mostly)  
- **`security_groups`** - list of VPC Security Groups (according to Yandex Cloud documentation it's limited to 5)  

## Application Load Balancer Block

ALB Specification describes load balancer for the environment

- **`target_port`** - port on workers that ingress controller listens to
- **`ext_port`** - ALB port for user connections
- **`nodes`** - list of backend nodes

balancer:
  target_port: 80
  ext_port: 80
  nodes:
  - worker11
  - worker12

## Network Block

This block is for subnets and security group creation.

- **`name`** - name of network. This network must exists.
- **`subnets`** - map of subnets to create
- **`security_groups`** - map of security groups to create

### Subnet Block

- **`zone`** - availability zone where the subnet will be created 
- **`subnets`** - list of CIDR which the subnet will utilize.

###  Security Groups Block

Each security group must have at least one block `egress` or `ingress`. Such block contain list of rules with the following specification:

- **`protocol`** - IP protocol `TCP` or `UDP`
- **`ports`** - port address, range or `-1` for all ports. Example of valid values: "80", "1024-65535", "-1"
- **`cidr`** - list of CIDR to apply

## Runner Block

This block is for k8s gitlab-runner deployment. It describes helm values and namespace for this task

**`enabled`** - boolean value for installation
**`name` - name of helm release
**`namespace`** - kubernetes namespace for installation. Default is `default`
**`helm_values`** - list of Values.yaml files 
**`k8s_manifests`** - additional kubernetes manifests to deploy.

## Monitoring Block

This block is for k8s monitoring deployment. It describes helm values and namespace for this task.

**`enabled`** - boolean value for installation
**`name`** - name of helm release
**`namespace`** - kubernetes namespace for installation. Default is `gitlab-runner`
**`helm_values`** - list of Values.yaml files 

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
          ports: -1
          cidr: [192.168.0.0/16]
        - protocol: udp
          ports: -1
          cidr: [192.168.0.0/16]
      egress:
        - protocol: tcp
          ports: -1
          cidr: [192.168.0.0/16]
        - protocol: udp
          ports: -1
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

balancer:
  target_port: 80
  ext_port: 80
  nodes:
  - master-dev13
```

