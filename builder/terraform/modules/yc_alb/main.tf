resource "yandex_alb_target_group" "targetgroup" {
  name      = "alb-target-group"

  dynamic "target" {
    for_each = var.instances
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      ip_address   = target.value.network_interface[0].ip_address
    }
  }
}


resource "yandex_alb_http_router" "router" {
  name      = "http-router"
}


resource "yandex_alb_backend_group" "group" {
  name      = "group"
  http_backend {
    name = "backend"
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
        path  = "/"
      }
    }
  }
}


resource "yandex_alb_virtual_host" "virtualhost" {
  name      = "virtualhost"
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
  name        = "balancer"
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
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ var.ext_port ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.router.id
      }
    }
  }
}