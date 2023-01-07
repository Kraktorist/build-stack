resource "yandex_alb_target_group" "targetgroup" {
  name      = "${var.ENV}-alb-target-group"
  dynamic "target" {
    for_each = var.instances
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      ip_address   = target.value.network_interface[0].ip_address
    }
  }
}


resource "yandex_alb_http_router" "router" {
  name      = "${var.ENV}-http-router"
}


resource "yandex_alb_backend_group" "group" {
  name      = "${var.ENV}-group"
  http_backend {
    name = "${var.ENV}-backend"
    weight = 1
    port = var.target_port
    target_group_ids = [yandex_alb_target_group.targetgroup.id]
    load_balancing_config {
      panic_threshold = 33
    }    
    healthcheck {
      timeout = "1s"
      interval = "1s"
      http_healthcheck {
        path  = "/healtz"
      }
    }
  }
}


resource "yandex_alb_virtual_host" "virtualhost" {
  name      = "${var.ENV}-virtualhost"
  http_router_id = yandex_alb_http_router.router.id
  route {
    name = "route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.group.id
        timeout = "3s"
      }
    }
  }
}


resource "yandex_alb_load_balancer" "balancer" {
  name        = "${var.ENV}-balancer"
  network_id  = var.network_id

  allocation_policy {
    dynamic "location" {
      for_each = var.subnets
      content {
        zone_id = location.value.zone
        subnet_id = location.value.id
      }
    }
  }

  listener {
    name = "${var.ENV}-alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ var.ext_port ]
    }    
    dynamic "http" {
      for_each = var.certificate_id == null ? [1] : []
      content {
        handler {
          http_router_id = yandex_alb_http_router.router.id
        }
      }
    }

    dynamic "tls" {
      for_each = var.certificate_id == null ? [] : [1]
      content {
        default_handler {
          certificate_ids = [ var.certificate_id ]
          http_handler {
            http_router_id = yandex_alb_http_router.router.id
          }
        }
      }
    }

  }
}