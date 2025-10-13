resource "yandex_alb_load_balancer" "alb-lb" {
  name       = "alb-lb"

  network_id = yandex_vpc_network.bastion-network.id

  security_group_ids = [ yandex_vpc_security_group.alb-security.id,
                         yandex_vpc_security_group.egress-security.id,
                         yandex_vpc_security_group.alb-vm-security.id,
                         yandex_vpc_security_group.external-ssh-security.id,
                         yandex_vpc_security_group.internal-ssh-security.id
                       ]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.bastion-external-segment.id 
    }
  }


  listener { 
    name = "alb-listener"
    
   endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.ngx-router.id
 
      }
    }
  }
}
