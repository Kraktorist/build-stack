data "yandex_compute_image" "os" {
  family = var.os_family
}

data "yandex_vpc_security_group" "group" {
  for_each = toset(setsubtract(var.node.security_groups, [for k, v in var.security_groups: v.name]))
  name = each.value
}

resource "yandex_compute_instance" "node" {
  zone = [ for v in var.subnets: try(v.zone) if var.node.subnet == v.name ][0]  
  name = var.node.name
  hostname = var.node.name
  allow_stopping_for_update = true
  resources {
    cores  = var.node.cpu
    memory = var.node.memory/1024
  }

  network_interface {
    subnet_id = [ for v in var.subnets: try(v.id) if var.node.subnet == v.name ][0]  
    nat = var.node.public_ip
    security_group_ids = [for o in merge(var.security_groups, data.yandex_vpc_security_group.group) : o.id if contains(var.node.security_groups, o.name)]
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      size = var.node.disk
    }
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_private_key_file)}"
  }
  labels = {
    env = var.ENV
  }
}
