# External ssh (Внешний)

resource "yandex_vpc_security_group" "external-ssh-security" {
  name                = "external-ssh-security"
  description         = "external ssh-security"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    description       = "Input TCP 22"
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 22
  }

  ingress {
    description       = "Input TCP SSH (internal-ssh-security) 22 port"
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.internal-ssh-security.id
    port              = 22
  }

  egress {
    description       = "Output all"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }

  egress {
    description       = "Output TCP 22 local SSH (internal-ssh-security)"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.internal-ssh-security.id
  }

}

# Internal ssh (Внутренний)

resource "yandex_vpc_security_group" "internal-ssh-security" {

  name                = "internal-ssh-security"
  description         = "Internal ssh"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    description       = "Input TCP 22"
    protocol          = "TCP"
    v4_cidr_blocks    = ["192.168.10.0/24"]
    port              = 22
  }

  egress {
    description       = "Output TCP 22 port"
    v4_cidr_blocks    = ["192.168.10.0/24"]
    protocol          = "TCP"
    port              = 22
  }

  egress {
    description       = "Output 22 port"
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }

}

# Balancer Input (На балансировщик внутренний)

resource "yandex_vpc_security_group" "alb-security" {
  name                = "alb-security"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  }

  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

# Balancer into Web-servers (От балансировщика на ngx-серверы)

resource "yandex_vpc_security_group" "alb-vm-security" {
  name                = "alb-vm-security"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.alb-security.id
    port              = 80
  }

  ingress {
    description       = "ssh"
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 22
  }

}

# All Output (Разрешен весь исх.трафик)

resource "yandex_vpc_security_group" "egress-security" {
  name                = "egress-security"
  network_id          = yandex_vpc_network.bastion-network.id

  egress {
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}

# Zabbix agent Security group

resource "yandex_vpc_security_group" "zabbix-security" {
  name                = "zabbix-security"
  network_id          = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.zabbix-server-security.id
    from_port         = 10050
    to_port           = 10051
  }

  egress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.zabbix-server-security.id
    from_port         = 10050
    to_port           = 10051
  }
}

# Zabbix server Security group

resource "yandex_vpc_security_group" "zabbix-server-security" {
  name        = "zabbix-server-security"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    from_port         = 10050
    to_port           = 10052
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks    = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    from_port         = 10050
    to_port           = 10051
  }

}

# Elasticsearch server security group

resource "yandex_vpc_security_group" "elastic-security" {
  name        = "elastic-security"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    port = 9200
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    port = 9200
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-internal-segment.v4_cidr_blocks
    port = 9300
  }

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = yandex_vpc_subnet.bastion-external-segment.v4_cidr_blocks
    port = 9300
  }

}

# Kibana server security group

resource "yandex_vpc_security_group" "kibana-security" {
  name        = "kibana-security"
  network_id  = yandex_vpc_network.bastion-network.id

  ingress {
    protocol          = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 5601
  }

}
