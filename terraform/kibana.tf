resource "yandex_compute_instance" "kibana" {

  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = false

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ichtldff870fce62q"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id

    security_group_ids = [
      yandex_vpc_security_group.internal-ssh-security.id,
      yandex_vpc_security_group.external-ssh-security.id,
      yandex_vpc_security_group.zabbix-security.id,
      yandex_vpc_security_group.kibana-security.id,
      yandex_vpc_security_group.egress-security.id
    ]

    nat        = true
    ip_address = "192.168.40.30"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }

}
