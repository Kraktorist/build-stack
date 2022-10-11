resource "yandex_vpc_network" "network" {
  name = var.network
}

resource "yandex_vpc_gateway" "default" {
  name = "foobar"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "routing" {
  network_id = yandex_vpc_network.network.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.default.id
  }
}

resource "yandex_vpc_subnet" "subnet" {
  for_each       = var.subnets
  network_id     = yandex_vpc_network.network.id
  name           = each.key
  zone           = each.value.zone
  v4_cidr_blocks = each.value.subnets
  route_table_id = yandex_vpc_route_table.routing.id
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
