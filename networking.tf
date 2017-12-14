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

  count = "${var.allow_ssh ? 1 : 0}"
}
