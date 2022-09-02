locals {
  # ssh_private_key_file = var.ssh_private_key_file != "" ? var.ssh_private_key_file : "${abspath(path.root)}/key"
  config = yamldecode(file(var.config))
  inventory = local.config.inventory.all
  params = local.config.params
  nodes = merge(flatten([
    [
      for group, members in try(local.inventory.children.k8s_cluster.children, {}): [
        {
          for node, params in members.hosts:
            node => {
                name = node,
                cpu = local.params[node].cpu
                memory = local.params[node].memory
                disk = local.params[node].disk
                zone = local.params[node].zone
                public_ip = local.params[node].public_ip
            }
        }
      ]
    ],
    [
      for group, members in try(local.inventory.children, {}): [
        {
          for node, params in members.hosts:
            node => {
                name = node,
                cpu = local.params[node].cpu
                memory = local.params[node].memory
                disk = local.params[node].disk
                zone = local.params[node].zone
                public_ip = local.params[node].public_ip
            }
        }
      ] if group != "k8s_cluster"
    ]
  ])...)
}


module ychosted {
  nodes = local.nodes
  params = local.params
  source = "./modules/ychosted/"
}

locals {
  ssh_user = module.ychosted.ssh_user
  vm = module.ychosted.vm
  nodes_ips = module.ychosted.worker_public_ips
}


module inventory {
  source = "./modules/ansible-inventory"
  ssh_user = local.ssh_user
  vm = local.vm
  inventory = local.inventory
}