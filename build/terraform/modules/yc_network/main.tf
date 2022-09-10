resource "yandex_vpc_network" "network" {
  name = var.network
}

resource "yandex_vpc_subnet" "subnet" {
  for_each       = var.subnets
  network_id     = yandex_vpc_network.network.id
  name           = each.key
  zone           = each.value.zone
  v4_cidr_blocks = each.value.subnets
}
