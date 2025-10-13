resource "yandex_compute_instance" "elasticsearch" {

  name                      = "elasticsearch"
  hostname                  = "elasticsearch"
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
    subnet_id = yandex_vpc_subnet.bastion-internal-segment.id

    security_group_ids = [
      yandex_vpc_security_group.internal-ssh-security.id,
      yandex_vpc_security_group.external-ssh-security.id,
      yandex_vpc_security_group.zabbix-security.id,
      yandex_vpc_security_group.elastic-security.id,
      yandex_vpc_security_group.egress-security.id
    ]
    nat        = false
    ip_address = "192.168.10.30"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }

}
