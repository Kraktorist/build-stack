data "yandex_compute_image" "os" {
  family = var.os_family
}

data "yandex_vpc_subnet" "subnet" {
  name = var.node.subnet
}

data "yandex_vpc_security_group" "group" {
  for_each = toset(var.node.security_groups)
  name = each.value
}

resource "yandex_compute_instance" "node" {
  zone = data.yandex_vpc_subnet.subnet.zone
  name = var.node.name
  hostname = var.node.name
  allow_stopping_for_update = true
  resources {
    cores  = var.node.cpu
    memory = var.node.memory/1024
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.subnet.id
    nat = var.node.public_ip
    # security_group_ids = data.yandex_vpc_security_group.group[*].security_group_id
    security_group_ids = [for o in data.yandex_vpc_security_group.group : o.security_group_id]
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
