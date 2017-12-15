# #################################################################
# Security Group rules for ECS instances
# #################################################################

# SSH <= in
resource "aws_security_group_rule" "ecs_instances_ssh_in" {
  description = "SSH from ssh_allowed_cidr"
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${var.ssh_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_ssh_in ? 1 : 0}"
}

# HTTP => out
resource "aws_security_group_rule" "ecs_instances_http_out" {
  description = "HTTP to http_allowed_cidr"
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["${var.http_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_http_out ? 1 : 0}"
}

# HTTPS => out
resource "aws_security_group_rule" "ecs_instances_https_out" {
  description = "HTTPS to https_allowed_cidr"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["${var.https_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_https_out ? 1 : 0}"
}

# Consul Gossip 8301 TCP <= in
resource "aws_security_group_rule" "ecs_instances_consul_8301_tcp_in" {
  description = "Consul LAN gossip"
  type        = "ingress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "tcp"
  cidr_blocks = ["${var.consul_gossip_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_consul_gossip ? 1 : 0}"
}

# Consul Gossip 8301 TCP => out
resource "aws_security_group_rule" "ecs_instances_consul_8301_tcp_out" {
  description = "Consul LAN gossip"
  type        = "egress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "tcp"
  cidr_blocks = ["${var.consul_gossip_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_consul_gossip ? 1 : 0}"
}

# Consul Gossip 8301 UDP <= in
resource "aws_security_group_rule" "ecs_instances_consul_8301_udp_in" {
  description = "Consul LAN gossip"
  type        = "ingress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "udp"
  cidr_blocks = ["${var.consul_gossip_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_consul_gossip ? 1 : 0}"
}

# Consul Gossip 8301 UDP => out
resource "aws_security_group_rule" "ecs_instances_consul_8301_udp_out" {
  description = "Consul LAN gossip"
  type        = "egress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "udp"
  cidr_blocks = ["${var.consul_gossip_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_consul_gossip ? 1 : 0}"
}

# Consul RDP => out
resource "aws_security_group_rule" "ecs_instances_consul_8300_tcp_out" {
  description = "Consul client RCP to consul server"
  type        = "egress"
  from_port   = 8300
  to_port     = 8300
  protocol    = "tcp"
  cidr_blocks = ["${var.consul_client_server_rdp_allowed_cidr}"]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_consul_client_server_rdp ? 1 : 0}"
}

# Logz.io EU => out
resource "aws_security_group_rule" "ecs_instances_logzio_8071_tcp_out" {
  description = "Logback to logz.io (EU)"
  type        = "egress"
  from_port   = 8071
  to_port     = 8071
  protocol    = "tcp"

  cidr_blocks = [
    "52.57.23.254/32",
    "52.57.24.166/32",
    "52.28.67.139/32",
    "52.57.102.144/32",
    "52.57.139.219/32",
    "35.157.100.82/32",
    "35.157.19.97/32",
    "35.157.71.116/32",
    "35.157.126.82/32",
    "35.157.104.194/32",
  ]

  security_group_id = "${aws_security_group.container_instance.id}"

  count = "${var.allow_logzio_eu_out ? 1 : 0}"
}
