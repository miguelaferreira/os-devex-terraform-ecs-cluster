# terraform-aws-ecs-cluster

A Terraform module to create an Amazon Web Services (AWS) EC2 Container Service (ECS) cluster.

**Fork of https://github.com/azavea/terraform-aws-ecs-cluster at version 1.0.0**

## Why a fork?

The authors of the [original module](https://github.com/azavea/terraform-aws-ecs-cluster) and the author of this module have [agreed to diverge in direction](https://github.com/azavea/terraform-aws-ecs-cluster/pull/19) for the module.
The author of this module is pursuing the direction of 100% automated operations on the ECS cluster.
To that end, this module contains elements to provide zero-downtime rolling updates of the cluster instances.

The approach followed here to achieve zero-downtime rolling updates is an implementation of the approach described in [this AWS blog post](https://aws.amazon.com/de/blogs/compute/how-to-automate-container-instance-draining-in-amazon-ecs/).
It combines building the auto scaling group for the container instances using a cloud formation stack (which provides the rolling update mechanism), with a lambda function that is triggered on instance termination events to make sure the container instance is drained of cluster service tasks before it gets terminated.

## Usage

```hcl
data "template_file" "container_instance_cloud_config" {
  template = "${file("cloud-config/container-instance.yml.tpl")}"

  vars {
    environment = "${var.environment}"
  }
}

module "ecs_cluster" {
  source = "git://gitlab.com/open-source-devex/terraform-modules/aws/ecs-cluster.git?ref=1.0.0"

  vpc_id        = "vpc-20f74844"
  ami_id        = "ami-b2df2ca4"
  instance_type = "t2.micro"
  key_name      = "hector"

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

  vpc_private_subnet_ids = [...]

  project     = "Something"
  environment = "Staging"
}
```

## Variables

- `vpc_id` - ID of VPC meant to house cluster
- `lookup_latest_ami` - lookup the latest Amazon-owned ECS AMI. If this variable is `true`, the latest ECS AMI will be used, even if `ami_id` is provided (default: `false`).
- `ami_id` - Cluster instance Amazon Machine Image (AMI) ID. If `lookup_latest_ami` is `true`, this variable will be silently ignored.
- `ami_owners` - List of accounts that own the AMI (default: `self, amazon, aws-marketplace`)
- `root_block_device_type` - Instance root block device type (default: `gp2`)
- `root_block_device_size` - Instance root block device size in gigabytes (default: `8`)
- `instance_type` - Instance type for cluster instances (default: `t2.micro`)
- `cloud_config_content` - user data supplied to launch configuration for cluster nodes
- `cloud_config_content_type` - the type of configuration being passed in as user data, see [EC2 user guide](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonLinuxAMIBasics.html#CloudInit) for a list of possible types (default: `text/cloud-config`)
- `health_check_grace_period` - Time in seconds after container instance comes into service before checking health (default: `600`)
- `desired_capacity` - Number of EC2 instances that should be running in cluster (default: `1`)
- `min_size` - Minimum number of EC2 instances in cluster (default: `0`)
- `max_size` - Maximum number of EC2 instances in cluster (default: `1`)
- `termination_policies` - Policies to use when deciding which instance to terminate (default: `["OldestLaunchConfiguration", "Default"]`)
- `rolling_update_max_batch_size` - Max number of instances to update at the same time (default: `1`)
- `rolling_update_pause_time` - How much time to wait between updating instances (default: `PT5M` - 5 minutes)
- `rolling_update_wait_on_signal` - Should rolling update wait for a signal sent from each new instance before moving on to the next
- `enabled_metrics` - A list of metrics to gather for the cluster
- `vpc_private_subnet_ids` - A list of private subnet IDs to launch cluster instances
- `scale_up_cooldown_seconds` - Number of seconds before allowing another scale up activity (default: `300`)
- `scale_down_cooldown_seconds` - Number of seconds before allowing another scale down activity (default: `300`)
- `high_cpu_evaluation_periods` - Number of evaluation periods for high CPU alarm (default: `2`)
- `high_cpu_period_seconds` - Number of seconds in an evaluation period for high CPU alarm (default: `300`)
- `high_cpu_threshold_percent` - Threshold as a percentage for high CPU alarm (default: `90`)
- `low_cpu_evaluation_periods` - Number of evaluation periods for low CPU alarm (default: `2`)
- `low_cpu_period_seconds` - Number of seconds in an evaluation period for low CPU alarm (default: `300`)
- `low_cpu_threshold_percent` - Threshold as a percentage for low CPU alarm (default: `10`)
- `high_memory_evaluation_periods` - Number of evaluation periods for high memory alarm (default: `2`)
- `high_memory_period_seconds` - Number of seconds in an evaluation period for high memory alarm (default: `300`)
- `high_memory_threshold_percent` - Threshold as a percentage for high memory alarm (default: `90`)
- `low_memory_evaluation_periods` - Number of evaluation periods for low memory alarm (default: `2`)
- `low_memory_period_seconds` - Number of seconds in an evaluation period for low memory alarm (default: `300`)
- `low_memory_threshold_percent` - Threshold as a percentage for low memory alarm (default: `10`)
- `project` - Name of project this cluster is for (default: ``)
- `environment` - Name of environment this cluster is targeting (default: `env`)
- `ecs_instance_daemon_tasks` - Number of tasks running as daemons on the cluster instances (default: `0`)
- `monitoring_enabled` - Sets the value of 'MonitoringEnabled' resource tag (default: `false`)
- `allow_ssh_in` - Set to true to configure SSH access to cluster instances (requires `ssh_public_key_file` and `ssh_allowed_cidr`). (default: `false`)
- `ssh_public_key_file` - an SSH key pair public file. (default: ``)
- `ssh_allowed_cidrs` - A list of CIDRs from which instances accept SSH connections. (default: ``)
- `allow_http_out` - Set to true to configure HTTP access from cluster instances (requires `http_allowed_cidr`). (default `false`)
- `http_allowed_cidrs` - A list of CIDRs to which instances can connect via HTTP.
- `allow_https_out` - Set to true to configure HTTPS access from cluster instances (requires `https_allowed_cidr`). (default `false`)
- `https_allowed_cidrs` - A list of CIDRs to which instances can connect via HTTPS.
- `allow_consul_gossip` - Set to true to configure Consul gossip ports to and from cluster instances (requires `consul_gossip_allowed_cidr`).
- `consul_gossip_allowed_cidrs` - A list of CIDRs to allow Consul gossip traffic to and from.
- `allow_consul_client_server_rdp` - Set to true to configure Consul RDP access from cluster instances (requires `consul_client_server_rdp_allowed_cidr`).
- `consul_client_server_rdp_allowed_cidrs` - A list of CIDRs to which instances can connect via Consul RDP
- `allow_logzio_eu_out` - Set to true to configure (logback appender to) logz.io (EU) access from cluster instances (requires `logzio_eu_allowed_cidr`).
- `enable_daemon_tasks` - Set to true to create the required IAM policies to allow cluster instances to start their own daemon tasks. (default: `false`)

## Outputs

- `id` - The container service cluster ID
- `name` - The container service cluster name
- `container_instance_security_group_id` - Security group ID of the EC2 container instances
- `container_instance_ecs_for_ec2_service_role_name` - Name of IAM role associated with EC2 container instances
- `ecs_service_role_name` - Name of IAM role for use with ECS services
- `ecs_autoscale_role_name` - Name of IAM role for use with ECS service autoscaling
- `ecs_service_role_arn` - ARN of IAM role for use with ECS services
- `ecs_autoscale_role_arn` - ARN of IAM role for use with ECS service autoscaling
- `container_instance_ecs_for_ec2_service_role_arn` - ARN of IAM role associated with EC2 container instances


## Contributing

Contributions to this module are very welcome, please fork this repository and submit merge requests.
We are trying an approach to testing based on test-kitchen and the [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform) plugin, so please consider adding tests to your merge requests.

### Run the tests

The integration tests require ruby and companion tools like bundler to be available on the command line.


```bash
cd integration-testing

touch secrets.tfvars
# edit secrets.tfvars to define terraform variables: 'aws_access_key_id', 'aws_secret_access_key' and 'aws_region'

bundle install                                    # to install test tooling

bundle exec kitchen converge                      # to provision the test infrastructure on AWS
bundle exec kitchen verify                        # to run the tests
bundle exec kitchen destroy                       # to destroy the test infrastructure
```

When creating the infrastructure to test agains (`kitchen converge`), kitchen requires the public IP of the instance being created by the autoscaling group.
Since terraform is not managing the instances directly, a data source is used in the test fixture to fetch the IP.
```hcl
data "aws_instances" "test" {
  instance_tags {
    Environment = "${var.name}"
  }

  depends_on = ["module.ecs_cluster"]
}
```
The explicit dependency on `module.ecs_cluster` is added to enforce that this data source should only be computed after the cluster is built (which doesn't mean that the instance will be ready, so it sometimes fails and needs a retry).
However, when modifying the launch configuration of the autoscaling group, terraform will report an dependency cycle.
In that case one needs to comment out the explicit dependency to allow terraform to make the modification.


# Copyright

* Copyright December 2017 - to date, Open Source DevEx and the 'open-source-devex/terraform-modules/aws/ecs-cluster' contributors
* Copyright March 2017 - December 2017, Azavea, Inc and the 'azavea/terraform-aws-ecs-cluster' contributors
