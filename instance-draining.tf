# #########################################
# Role for executing lambdas
# #########################################
resource "aws_iam_role" "instance_draining_lambda" {
  name = "${local.resource_name_suffix}LambdaECSInstanceDraining"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "instance_draining_lambda" {
  name        = "${local.resource_name_suffix}LambdaECSInstanceDraining"
  path        = "/"
  description = "Policy to enable lambda functions to trigger ECS instance draining"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeHosts",
        "ecs:ListContainerInstances",
        "ecs:SubmitContainerStateChange",
        "ecs:SubmitTaskStateChange",
        "ecs:DescribeContainerInstances",
        "ecs:UpdateContainerInstancesState",
        "ecs:ListTasks",
        "ecs:DescribeTasks",
        "sns:Publish",
        "sns:ListSubscriptions"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_draining_lambda_execute" {
  role       = "${aws_iam_role.instance_draining_lambda.name}"
  policy_arn = "${aws_iam_policy.instance_draining_lambda.arn}"
}

resource "aws_iam_role_policy_attachment" "instance_draining_lambda_autocaling_notifications" {
  role       = "${aws_iam_role.instance_draining_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
}

# #########################################
# Role to allow ASG sending notifications through SNS (to a lambda)
# #########################################
resource "aws_iam_role" "autoscaling_to_sns" {
  name = "${local.resource_name_suffix}AutoscalingToSNS"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "autoscaling_to_sns_autocaling_notifications" {
  role       = "${aws_iam_role.autoscaling_to_sns.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
}

# #########################################
# Lambda function
# #########################################
variable "instance_drainer_function_name" {
  default = "Drainer"
}

variable "instance_drainer_function_description" {
  default = "Extension to autoscaling lifecycle to drain ECS cluster instances before terminating them"
}

variable "instance_draining_function_jar" {
  default = "lambda/ecs-instance-draining-v0.1-aws.jar"
}

variable "instance_draining_function_handler" {
  default = "org.springframework.cloud.function.adapter.aws.SpringBootStreamHandler"
}

variable "instance_draining_function_runtime" {
  default = "java8"
}

variable "instance_draining_function_memory" {
  default = "512"
}

variable "instance_draining_function_timeout" {
  default = "180"
}

resource "aws_lambda_function" "instance_draining" {
  filename         = "${var.instance_draining_function_jar}"
  function_name    = "${var.instance_drainer_function_name}"
  description      = "${var.instance_drainer_function_description}"
  role             = "${aws_iam_role.instance_draining_lambda.arn}"
  handler          = "${var.instance_draining_function_handler}"
  source_code_hash = "${base64sha256(file("${var.instance_draining_function_jar}"))}"
  runtime          = "${var.instance_draining_function_runtime}"
  memory_size      = "${var.instance_draining_function_memory}"
  timeout          = "${var.instance_draining_function_timeout}"

  environment {
    variables = "${merge(
        local.common_tags,
        map(
          "Name", "${var.instance_drainer_function_name}",
          "LIFECYCLE_HOOK_NAME", "${aws_autoscaling_lifecycle_hook.instance_draining.name}"
        )
      )}"
  }
}

# #########################################
# SNS Topic
# #########################################
resource "aws_sns_topic" "autoscaling" {
  name = "${local.resource_name_suffix}EC2Autoscaling"
}

resource "aws_sns_topic_subscription" "autoscaling_lambda" {
  topic_arn = "${aws_sns_topic.autoscaling.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.instance_draining.arn}"
}

resource "aws_lambda_permission" "autoscaling_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.instance_draining.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.autoscaling.arn}"
}

# #########################################
# Autoscaling Lifecycle hook
# #########################################
resource "aws_autoscaling_lifecycle_hook" "instance_draining" {
  name                   = "${local.resource_name_suffix}InstanceDraining"
  autoscaling_group_name = "${aws_cloudformation_stack.autoscaling_group.outputs["name"]}"
  default_result         = "ABANDON"
  heartbeat_timeout      = 900
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"

  notification_metadata = <<EOF
{
  "ecsInstanceDaemonTasksCount": "${var.ecs_instance_daemon_tasks}"
}
EOF

  notification_target_arn = "${aws_sns_topic.autoscaling.arn}"
  role_arn                = "${aws_iam_role.autoscaling_to_sns.arn}"
}
