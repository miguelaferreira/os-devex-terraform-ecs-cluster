# #################################################################
# Locals
# #################################################################
locals {
  common_tags = {
    Project     = "${var.project}"
    Environment = "${var.environment}"
    Monitoring  = "${var.monitoring_enabled}"
  }

  resource_name_suffix = "${title(var.project)}${title(var.environment)}"
}

# #################################################################
# SSH key pair for cluster instances
# #################################################################
resource "aws_key_pair" "ecs_instances" {
  key_name   = "${local.resource_name_suffix}ECSInstance"
  public_key = "${file(var.ssh_public_key_file)}"
}

#
# Container Instance IAM resources
#
data "aws_iam_policy_document" "container_instance_ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "container_instance_ec2" {
  name               = "${local.resource_name_suffix}ContainerInstanceProfile"
  assume_role_policy = "${data.aws_iam_policy_document.container_instance_ec2_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ec2_service_role" {
  role       = "${aws_iam_role.container_instance_ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = "${aws_iam_role.container_instance_ec2.name}"
  role = "${aws_iam_role.container_instance_ec2.name}"
}

#
# ECS Service IAM permissions
#

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "${local.resource_name_suffix}EcsServiceRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_role" {
  role       = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs_autoscale_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = "${local.resource_name_suffix}EcsAutoscaleRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_autoscale_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_autoscaling_role" {
  role       = "${aws_iam_role.ecs_autoscale_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

#
# Security group resources
#
resource "aws_security_group" "container_instance" {
  vpc_id = "${var.vpc_id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "sgContainerInstance"
    )
  )}"
}

#
# AutoScaling resources
#
data "template_file" "container_instance_base_cloud_config" {
  template = "${file("${path.module}/cloud-config/base-container-instance.yml.tpl")}"

  vars {
    ecs_cluster_name = "${aws_ecs_cluster.container_instance.name}"
  }
}

data "template_cloudinit_config" "container_instance_cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.container_instance_base_cloud_config.rendered}"
  }

  part {
    content_type = "${var.cloud_config_content_type}"
    content      = "${var.cloud_config_content}"
  }
}

data "aws_ami" "ecs_ami" {
  count       = "${var.lookup_latest_ami ? 1 : 0}"
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["${var.ami_owners}"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "user_ami" {
  count  = "${var.lookup_latest_ami ? 0 : 1}"
  owners = ["${var.ami_owners}"]

  filter {
    name   = "image-id"
    values = ["${var.ami_id}"]
  }
}

resource "aws_launch_configuration" "container_instance" {
  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "${var.root_block_device_type}"
    volume_size = "${var.root_block_device_size}"
  }

  name_prefix          = "${local.resource_name_suffix}ECSCluster-"
  iam_instance_profile = "${aws_iam_instance_profile.container_instance.name}"

  # Using join() is a workaround for depending on conditional resources.
  # https://github.com/hashicorp/terraform/issues/2831#issuecomment-298751019
  image_id = "${var.lookup_latest_ami ? join("", data.aws_ami.ecs_ami.*.image_id) : join("", data.aws_ami.user_ami.*.image_id)}"

  instance_type   = "${var.instance_type}"
  key_name        = "${aws_key_pair.ecs_instances.key_name}"
  security_groups = ["${aws_security_group.container_instance.id}"]
  user_data       = "${data.template_cloudinit_config.container_instance_cloud_config.rendered}"
}

# In-depth discussion on the rolling update mechanism found in: https://github.com/hashicorp/terraform/issues/1552#issuecomment-191847434
# AWS docuemntation here: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html
resource "aws_cloudformation_stack" "autoscaling_group" {
  lifecycle {
    create_before_destroy = true
  }

  name = "${local.resource_name_suffix}ECSCluster"

  template_body = <<EOF
{
  "Resources": {
    "asg${title(var.environment)}ContainerInstance": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "LaunchConfigurationName": "${aws_launch_configuration.container_instance.name}",
        "HealthCheckGracePeriod": "${var.health_check_grace_period}",
        "HealthCheckType": "EC2",
        "DesiredCapacity": "${var.desired_capacity}",
        "TerminationPolicies": ["${join("\",\"", var.termination_policies)}"],
        "MaxSize": "${var.max_size}",
        "MinSize": "${var.min_size}",
        "VPCZoneIdentifier": ["${join("\",\"", var.private_subnet_ids)}"],
        "MetricsCollection": [
            {
                "Granularity" : "1Minute",
                "Metrics" : ["${join("\",\"", var.enabled_metrics)}"]
            }
        ],
        "Tags": [
            {
               "Key" : "Name",
               "Value" : "ContainerInstance",
               "PropagateAtLaunch" : true
            },
            {
               "Key" : "Project",
               "Value" : "${var.project}",
               "PropagateAtLaunch" : true
            },
            {
               "Key" : "Environment",
               "Value" : "${var.environment}",
               "PropagateAtLaunch" : true
            }
        ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "${var.min_size}",
          "MaxBatchSize": "${var.rolling_update_max_batch_size}",
          "WaitOnResourceSignals": "${var.rolling_update_wait_on_signal ? "true" : "false"}",
          "PauseTime": "${var.rolling_update_pause_time}"
        }
      }
    }
  },
  "Outputs": {
    "name": {
      "Description": "The name of the auto scaling group",
       "Value": {"Ref": "asg${title(var.environment)}ContainerInstance"}
    }
  }
}
EOF
}

#
# ECS resources
#
resource "aws_ecs_cluster" "container_instance" {
  name = "${local.resource_name_suffix}"
}

#
# CloudWatch resources
#
resource "aws_autoscaling_policy" "container_instance_scale_out" {
  name                   = "${local.resource_name_suffix}ECSClusterScaleOut"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_up_cooldown_seconds}"
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["name"]}"
}

resource "aws_autoscaling_policy" "container_instance_scale_in" {
  name                   = "${local.resource_name_suffix}ECSClusterScaleIn"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_down_cooldown_seconds}"
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["name"]}"
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_cpu" {
  alarm_name          = "${local.resource_name_suffix}ECSClusterCPUReservationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.high_cpu_evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.high_cpu_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.high_cpu_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale out if CPUReservation is above N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_cpu" {
  alarm_name          = "${local.resource_name_suffix}ECSClusterCPUReservationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.low_cpu_evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.low_cpu_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.low_cpu_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale in if the CPUReservation is below N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_in.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_memory" {
  alarm_name          = "${local.resource_name_suffix}ECSClusterMemoryReservationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.high_memory_evaluation_periods}"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "${var.high_memory_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.high_memory_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale out if the MemoryReservation is above N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_out.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_low_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_memory" {
  alarm_name          = "${local.resource_name_suffix}ECSClusterMemoryReservationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.low_memory_evaluation_periods}"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "${var.low_memory_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.low_memory_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale in if the MemoryReservation is below N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_in.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_memory"]
}
