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

module yc_certificate {
  count = can(module.input.params.certificate) ? 1 : 0
  domains = module.input.params.certificate.domains
  name = module.input.params.certificate.name
  wait_validation = module.input.params.certificate.wait_validation
  source = "./modules/yc_certificate/"
  ENV = var.ENV
}

module yc_alb {
  count = can(module.input.params.balancer) ? 1 : 0
  instances = [for k, v in module.yc_instance: v.instances if contains(module.input.params.balancer.nodes, v.instances.name)]
  network_id = module.yc_network[0].network_id
  subnets = module.yc_network[0].subnets
  target_port = module.input.params.balancer.target_port
  ext_port = module.input.params.balancer.ext_port
  certificate_id = module.input.params.balancer.tls ? module.yc_certificate[0].certificate_id : null
  #certificate = can(module.input.params.balancer.certificate) ? module.input.params.balancer.certificate : null
  source = "./modules/yc_alb/"
  ENV = var.ENV
}

module inventory {
  source = "./modules/inventory"
  inventory = module.input.inventory
  ansible_inventory = var.ansible_inventory
  instances = [for k, v in module.yc_instance: v.instances]
}

# data "yandex_alb_load_balancer" "alb" {
#   name = "test"
# }

# output name {
#   value       = data.yandex_alb_load_balancer.alb
# }
