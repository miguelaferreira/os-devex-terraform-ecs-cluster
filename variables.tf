variable "project" {
  description = "Name of project this cluster is for. Sets the value of 'MonitoringEnabled' resource tag"
  default     = ""
}

variable "environment" {
  description = "Name of environment this cluster is targeting. Sets the value of 'MonitoringEnabled' resource tag"
  default     = "env"
}

variable "ecs_instance_daemon_tasks" {
  description = "Number of tasks running as daemons on the cluster instances"
  default     = 0
}

variable "monitoring_enabled" {
  description = "Sets the value of 'MonitoringEnabled' resource tag"
  default     = false
}

variable "vpc_id" {}

variable "allow_ssh_in" {
  description = "Set to true to configure SSH access to cluster instances (requires `ssh_public_key_file` and `ssh_allowed_cidr`)."
  default     = false
}

variable "ssh_public_key_file" {
  description = "A publick key file to provide SSH access to the cluster instances"
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "A list of CIDRs from which instances accept SSH connections."
  type        = "list"
  default     = []
}

variable "allow_http_out" {
  description = "Set to true to configure HTTP access from cluster instances (requires `http_allowed_cidr`)."
  default     = false
}

variable "http_allowed_cidrs" {
  description = "A list of CIDRs to which instances can connect via HTTP."
  type        = "list"
  default     = []
}

variable "allow_https_out" {
  description = "Set to true to configure HTTPS access from cluster instances (requires `https_allowed_cidr`)."
  default     = false
}

variable "https_allowed_cidrs" {
  description = "A list of CIDRs to which instances can connect via HTTPS."
  type        = "list"
  default     = []
}

variable "allow_consul_gossip" {
  description = "Set to true to configure Consul gossip ports to and from cluster instances (requires `https_allowed_cidr`)."
  default     = false
}

variable "consul_gossip_allowed_cidrs" {
  description = "A list of CIDRs to allow Consul gossip traffic to and from."
  type        = "list"
  default     = []
}

variable "allow_consul_client_server_rdp" {
  description = "Set to true to configure Consul RDP access from cluster instances (requires `https_allowed_cidr`)."
  default     = false
}

variable "consul_client_server_rdp_allowed_cidrs" {
  description = "A list of CIDRs to which instances can connect via Consul RDP"
  type        = "list"
  default     = []
}

variable "allow_logzio_eu_out" {
  description = "Set to true to configure (logback appender to) logz.io (EU) access from cluster instances (requires `logzio_eu_allowed_cidr`)."
  default     = false
}

variable "enable_daemon_tasks" {
  description = "Set to true to create the required IAM policies to allow cluster instances to start their own daemon tasks"
  default     = "false"
}

variable "termination_policies" {
  default = ["OldestLaunchConfiguration", "Default"]
}

variable "rolling_update_max_batch_size" {
  default = 1
}

variable "rolling_update_pause_time" {
  default = "PT5M"
}

variable "rolling_update_wait_on_signal" {
  default = false
}

variable "ami_id" {
  default = "ami-6944c513"
}

variable "ami_owners" {
  default = ["self", "amazon", "aws-marketplace"]
}

variable "lookup_latest_ami" {
  default = false
}

variable "root_block_device_type" {
  default = "gp2"
}

variable "root_block_device_size" {
  default = "8"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "cloud_config_content" {}

variable "cloud_config_content_type" {
  default = "text/cloud-config"
}

variable "health_check_grace_period" {
  default = "600"
}

variable "desired_capacity" {
  default = "1"
}

variable "min_size" {
  default = "1"
}

variable "max_size" {
  default = "1"
}

variable "enabled_metrics" {
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  type = "list"
}

variable "vpc_private_subnet_ids" {
  type = "list"
}

variable "scale_up_cooldown_seconds" {
  default = "300"
}

variable "scale_down_cooldown_seconds" {
  default = "300"
}

variable "high_cpu_evaluation_periods" {
  default = "2"
}

variable "high_cpu_period_seconds" {
  default = "300"
}

variable "high_cpu_threshold_percent" {
  default = "90"
}

variable "low_cpu_evaluation_periods" {
  default = "2"
}

variable "low_cpu_period_seconds" {
  default = "300"
}

variable "low_cpu_threshold_percent" {
  default = "10"
}

variable "high_memory_evaluation_periods" {
  default = "2"
}

variable "high_memory_period_seconds" {
  default = "300"
}

variable "high_memory_threshold_percent" {
  default = "90"
}

variable "low_memory_evaluation_periods" {
  default = "2"
}

variable "low_memory_period_seconds" {
  default = "300"
}

variable "low_memory_threshold_percent" {
  default = "10"
}
