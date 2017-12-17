# #########################################
# Autoscaling policies
# #########################################
resource "aws_autoscaling_policy" "container_instance_scale_out" {
  name                   = "${local.resource_name_suffix}ECSClusterScaleOut"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_out_cooldown_seconds}"
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["name"]}"
}

resource "aws_autoscaling_policy" "container_instance_scale_in" {
  name                   = "${local.resource_name_suffix}ECSClusterScaleIn"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_in_cooldown_seconds}"
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["name"]}"
}

# #########################################
# CloudWatch resources
# #########################################
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
