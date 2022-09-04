module yc_instance {
  for_each = module.input.params.hosts
  node = each.value
  source = "./modules/yc_instance/"
}

module inventory {
  source = "./modules/inventory"
  vm = module.yc_instance
  inventory = module.input.inventory
}
