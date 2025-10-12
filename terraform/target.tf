#Target Groups

resource "yandex_alb_target_group" "target-web" {
  name = "target-web"

  target {
    subnet_id  = yandex_vpc_subnet.bastion-internal-segment.id
    ip_address = yandex_compute_instance.nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.bastion-internal-segment.id
    ip_address = yandex_compute_instance.nginx-2.network_interface.0.ip_address
  }
}
