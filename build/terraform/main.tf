module input {
  config = var.config
  source = "./modules/input/"
}

module ychosted {
  nodes = module.input.nodes
  params = module.input.params
  source = "./modules/ychosted/"
}

locals {
  ssh_user = module.ychosted.ssh_user
  vm = module.ychosted.vm
  nodes_ips = module.ychosted.worker_public_ips
}


module inventory {
  source = "./modules/inventory"
  ssh_user = local.ssh_user
  vm = local.vm
  inventory = module.input.inventory
}