module input {
  config = var.config
  source = "./modules/input/"
}

module yc_network {
  count = can(module.input.params.network.name) ? 1 : 0
  network = module.input.params.network.name
  subnets = module.input.params.network.subnets
  security_groups = can(module.input.params.network.security_groups) ? module.input.params.network.security_groups : {}
  source = "./modules/yc_network/"
}

module yc_instance {
  for_each = try(module.input.params.hosts, {})
  node = each.value
  subnets = module.yc_network[0].subnets
  security_groups = module.yc_network[0].security_groups
  source = "./modules/yc_instance/"
  ENV = var.ENV
}

module inventory {
  source = "./modules/inventory"
  inventory = module.input.inventory
  ansible_inventory = var.ansible_inventory
  instances = [for k, v in module.yc_instance: v.instances]
}