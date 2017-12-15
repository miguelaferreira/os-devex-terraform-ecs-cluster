resource "aws_iam_policy" "start_daemon_task" {
  count = "${var.enable_daemon_tasks ? 1 : 0}"

  name        = "ecs-instance-start-task"
  path        = "/"
  description = "Policy to ECS instances to start ECS tasks"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:DescribeTasks",
        "ecs:StartTask",
        "ecs:DescribeTaskDefinition"
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

resource "aws_iam_role_policy_attachment" "start_daemon_task" {
  count = "${var.enable_daemon_tasks ? 1 : 0}"

  role       = "${aws_iam_role.container_instance_ec2.name}"
  policy_arn = "${aws_iam_policy.start_task.arn}"
}
