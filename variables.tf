# SPDX-License-Identifier: Apache-2.0

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)

  validation {
    condition     = length(var.tags) > 0
    error_message = "Tags must not be empty."
  }
}

variable "key_pair_create" {
  description = "Whether to create a new SSH key pair for EC2 access."
  type        = bool
}

variable "key_path" {
  description = "Path to the public key for SSH access, e.g. `~/.ssh/aws.pub`."
  type        = string
  sensitive   = true
  default     = null
}

variable "vpc_create" {
  description = "Whether to create a new VPC."
  type        = bool
  default     = false
}

variable "dtrack_ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string

  validation {
    condition     = contains(["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"], var.dtrack_ec2_instance_type)
    error_message = "EC2 instance type must be one of t3.nano, t3.micro, t3.small, t3.medium, t3.large, t3.xlarge, or t3.2xlarge."
  }
}

variable "ec2_subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type        = string
  default     = null
}

variable "dtrack_ebs_root_size" {
  description = "Size of the root EBS volume in GB."
  type        = number

  validation {
    condition     = var.dtrack_ebs_root_size >= 8 && var.dtrack_ebs_root_size <= 64
    error_message = "Root volume size must be between 8 and 64 GB."
  }
}

variable "dtrack_ebs_data_size" {
  description = "Size of the data EBS volume in GB."
  type        = number

  validation {
    condition     = var.dtrack_ebs_data_size >= 10 && var.dtrack_ebs_data_size <= 128
    error_message = "Data volume size must be between 10 and 128 GB."
  }
}

variable "dtrack_ebs_data_throughput" {
  description = "The data EBS volume throughput in MiB/s."
  type        = number
  default     = 125
}

variable "dtrack_ebs_data_snapshot_id" {
  description = "Snapshot ID to use for the data EBS volume."
  type        = string
  default     = null
}

variable "dtrack_name" {
  description = "The name for resources."
  type        = string
  default     = "component-analysis"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.dtrack_name))
    error_message = "Resource name can only include alphanumeric characters, dashes (-), or underscores (_)."
  }
}

variable "dtrack_security_group_ingress_cidr_blocks" {
  description = "List of IPv4 CIDR blocks allowed for ingress, e.g., `0.0.0.0/0` refers to the entire IPv4 address space."
  type        = list(string)
  # default     = []

  # validation {
  #   condition     = alltrue([for cidr in var.dtrack_security_group_ingress_cidr_blocks : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
  #   error_message = "Public IPv4 ingress (0.0.0.0/0) is not permitted by default."
  # }
  default = ["0.0.0.0/0"]
}

variable "dtrack_security_group_ingress_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed for ingress, e.g., `::/0` refers to the entire IPv6 address space."
  type        = list(string)
  # default     = []

  # validation {
  #   condition = alltrue([
  #     for cidr in var.dtrack_security_group_ingress_ipv6_cidr_blocks :
  #     can(regex("^([0-9a-fA-F:]+)/(?:\\d|[1-9]\\d|1[01]\\d|12[0-8])$", cidr)) && cidr != "::/0"
  #   ])
  #   error_message = "Each IPv6 entry must be a valid CIDR (prefix 0-128) and not be ::/0 by default."
  # }
  default = ["::/0"]
}

variable "dtrack_security_group_ingress_rules" {
  description = "List of ingress rules for the security group."
  type        = list(string)
  # default     = ["https-443-tcp", "ssh-tcp", "all-icmp"]

  # validation {
  #   condition     = length(var.dtrack_security_group_ingress_rules) > 0
  #   error_message = "At least one ingress rule must be specified."
  # }
  default = ["http-80-tcp", "https-443-tcp", "ssh-tcp", "all-icmp"]
}

variable "dtrack_security_group_egress_rules" {
  description = "List of egress rules for the security group."
  type        = list(string)
  # default     = ["https-443-tcp"]

  # validation {
  #   condition     = length(var.dtrack_security_group_egress_rules) > 0
  #   error_message = "At least one egress rule must be specified."
  # }
  default = ["all-all"]
}

variable "dtrack_eip_create" {
  description = "Specifies whether a public EIP will be created and associated with the instance."
  type        = bool
  default     = false
}

variable "dtrack_ebs_data_create" {
  description = "Whether to create and attach a data EBS volume."
  type        = bool
  default     = true
}
