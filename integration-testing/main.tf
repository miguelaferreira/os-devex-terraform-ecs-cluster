# #################################################################
# Configure AWS provider
# #################################################################
variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
}

# #################################################################
# Configure VPC
# #################################################################
variable "name" {
  default = "integrationTest"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  default = ["10.0.1.0/24"]
}

variable "aws_azs" {
  default = ["eu-central-1a"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.12.0"

  name = "${var.name}"
  cidr = "${var.vpc_cidr}"

  azs            = "${var.aws_azs}"
  public_subnets = "${var.vpc_public_subnets}"

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# #################################################################
# Configure ECS
# #################################################################
module "ecs_cluster" {
  source = "../"

  vpc_id               = "${module.vpc.vpc_id}"
  lookup_latest_ami    = true
  instance_type        = "t2.micro"
  key_name             = "${aws_key_pair.ecs_instances.key_name}"
  cloud_config_content = "${data.template_file.container_instance_cloud_config.rendered}"

  root_block_device_type = "gp2"
  root_block_device_size = "10"

  health_check_grace_period = "600"
  desired_capacity          = "1"
  min_size                  = "0"
  max_size                  = "1"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  private_subnet_ids = ["${module.vpc.public_subnets}"]

  instance_draining_function_jar = "../lambda/ecs-instance-draining-v0.1-aws.jar"

  project     = "Something"
  environment = "${var.name}"
}

resource "aws_key_pair" "ecs_instances" {
  key_name   = "test-key"
  public_key = "${file("files/id_rsa.pub")}"
}

data "aws_instances" "test" {
  instance_tags {
    Environment = "${var.name}"
  }

  depends_on = ["module.ecs_cluster"]
}

data "template_file" "container_instance_cloud_config" {
  template = "${file("files/container-instance.yml.tpl")}"

  vars {
    environment = "${var.name}"
  }
}

# #################################################################
# Configure networking
# #################################################################
resource "aws_security_group_rule" "ecs_instances_ssh_in" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${module.ecs_cluster.container_instance_security_group_id}"
}

resource "aws_security_group_rule" "ecs_instances_http_out" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${module.ecs_cluster.container_instance_security_group_id}"
}

resource "aws_security_group_rule" "ecs_instances_https_out" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${module.ecs_cluster.container_instance_security_group_id}"
}
