data "yandex_compute_image" "os" {
  family = var.os_family
}

# resource "yandex_resourcemanager_folder" "folder" {
#   cloud_id = var.params.cloud_id
#   name = var.params.folder
# }

resource "yandex_vpc_network" "network" {
  # folder_id = yandex_resourcemanager_folder.folder.id
  name = var.params.network
}

resource "yandex_vpc_subnet" "subnet" {
  for_each = var.params.subnets
  v4_cidr_blocks = each.value
  zone = each.key
  network_id     = yandex_vpc_network.network.id
}

resource "yandex_compute_instance" "node" {
  for_each = var.nodes
  # folder_id = yandex_resourcemanager_folder.folder.id
  zone = each.value.zone
  name = each.value.name
  resources {
    cores  = each.value.cpu
    memory = each.value.memory/1024
  }

  network_interface {
    # subnet_id = yandex_vpc_subnet.subnet.id
    subnet_id = yandex_vpc_subnet.subnet[each.value.zone].id
    nat = each.value.public_ip
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      size = each.value.disk
    }
  }
  metadata = {
    type      = each.key
    ssh-keys = "${var.ssh_user}:${file(var.ssh_private_key_file)}"
  }
}
