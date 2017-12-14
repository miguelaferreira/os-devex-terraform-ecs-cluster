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
