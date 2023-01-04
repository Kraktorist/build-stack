data "yandex_vpc_network" "network" {
  name = var.network
}

data "yandex_vpc_route_table" "routing" {
  name = "routing"
}

resource "yandex_vpc_subnet" "subnet" {
  for_each       = var.subnets
  network_id     = data.yandex_vpc_network.network.id
  name           = each.key
  zone           = each.value.zone
  v4_cidr_blocks = each.value.subnets
  route_table_id = data.yandex_vpc_route_table.routing.id
}

resource "yandex_vpc_security_group" "security_group" {
  for_each    = var.security_groups
  network_id  = data.yandex_vpc_network.network.id
  name        = each.key
  description = ""

  dynamic "ingress" {
    for_each = can(each.value.ingress) ? each.value.ingress : []
      content {
      protocol       = ingress.value.protocol
      description    = ""
      v4_cidr_blocks = ingress.value.cidr
      from_port      = regex("(\\d{1,5})-?(\\d{1,5})?",ingress.value.ports)[0]
      to_port        = coalesce(regex("(\\d{1,5})-?(\\d{1,5})?",ingress.value.ports)[1],regex("(\\d{1,5})-?(\\d{1,5})?",ingress.value.ports)[0])
      #port           = ingress.value.ports
    }
  }
  dynamic "egress" {
    for_each = can(each.value.egress) ? each.value.egress : []
      content {
      protocol       = egress.value.protocol
      description    = ""
      v4_cidr_blocks = egress.value.cidr
      from_port      = regex("(\\d{1,5})-?(\\d{1,5})?", egress.value.ports)[0]
      to_port        = coalesce(regex("(\\d{1,5})-?(\\d{1,5})?", egress.value.ports)[1],regex("(\\d{1,5})-?(\\d{1,5})?", egress.value.ports)[0])
      #port           = ingress.value.ports
    }
  }
}
