locals {
  # ssh_private_key_file = var.ssh_private_key_file != "" ? var.ssh_private_key_file : "${abspath(path.root)}/key"
  config = yamldecode(file(var.config))
  inventory = local.config.inventory.all
  hosts = local.config.hosts
  nodes = merge(flatten([
    [
      for group, members in try(local.inventory.children.k8s_cluster.children, {}): [
        {
          for node, params in members.hosts:
            node => {
                name = node,
                cpu = local.hosts[node].cpu
                memory = local.hosts[node].memory
                disk = local.hosts[node].disk
                subnet = local.hosts[node].subnet
                public_ip = local.hosts[node].public_ip
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
                cpu = local.hosts[node].cpu
                memory = local.hosts[node].memory
                disk = local.hosts[node].disk
                subnet = local.hosts[node].subnet
                public_ip = local.hosts[node].public_ip
            }
        }
      ] if group != "k8s_cluster"
    ]
  ])...)
}