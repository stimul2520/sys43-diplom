## HTTP router

resource "yandex_alb_http_router" "ngx-router" {
  name = "ngx-router"
}

resource "yandex_alb_virtual_host" "vt-host" {
  name           = "vt-host"
  http_router_id = yandex_alb_http_router.ngx-router.id

  route {
    name = "my-route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.ngx-backend.id # ID созданной ранее backend группы
        timeout          = "60s"
      }
    }
  }
}
