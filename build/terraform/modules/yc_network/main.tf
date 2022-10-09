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

resource "yandex_vpc_security_group" "security_group" {
  for_each    = var.security_groups
  network_id  = yandex_vpc_network.network.id
  name        = each.key
  description = ""

  dynamic "ingress" {
    for_each = can(each.value.ingress) ? each.value.ingress : []
      content {
      protocol       = ingress.value.protocol
      description    = ""
      v4_cidr_blocks = ingress.value.cidr
      port           = ingress.value.ports
    }
  }
  dynamic "egress" {
    for_each = can(each.value.egress) ? each.value.egress : []
      content {
      protocol       = egress.value.protocol
      description    = ""
      v4_cidr_blocks = egress.value.cidr
      port           = egress.value.ports
    }
  }
}
