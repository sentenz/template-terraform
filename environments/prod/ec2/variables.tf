# SPDX-License-Identifier: Apache-2.0

variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = contains(["eu-west-1", "eu-central-1"], var.region)
    error_message = "The AWS region must be one of the following: eu-west-1, eu-central-1."
  }
}

variable "profile" {
  description = "The AWS credentials stored in `~/.aws/credentials` under a specific profile."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Global resource tags."
  type        = map(string)
  default = {
    Name        = "Component Analysis"
    Terraform   = "true"
    Environment = "Prod"
    Owner       = "DevOps"
  }

  validation {
    condition     = length(var.tags) > 0
    error_message = "Tags must not be empty."
  }
}

variable "key_pair_create" {
  description = "Whether to create a new SSH key pair for EC2 access."
  type        = bool
  default     = true
}

variable "key_path" {
  description = "Path to the public key for SSH access."
  type        = string
  default     = "~/.ssh/sshkey.pub"
  sensitive   = true

  validation {
    condition     = can(regex("^.*\\.pub$", var.key_path))
    error_message = "The key_path must be a valid path to a public key file ending with '.pub'."
  }
}

variable "vpc_create" {
  description = "Whether to create a new VPC."
  type        = bool
  default     = false
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

variable "dtrack_ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string
  default     = "t3.xlarge"

  validation {
    condition     = contains(["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"], var.dtrack_ec2_instance_type)
    error_message = "EC2 instance type must be one of t3.nano, t3.micro, t3.small, t3.medium, t3.large, t3.xlarge, or t3.2xlarge."
  }
}

variable "dtrack_ebs_root_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 30

  validation {
    condition     = var.dtrack_ebs_root_size >= 8 && var.dtrack_ebs_root_size <= 256
    error_message = "Root volume size must be between 8 and 256 GB."
  }
}

variable "dtrack_ebs_data_create" {
  description = "Whether to create and attach a data EBS volume."
  type        = bool
  default     = true
}

variable "dtrack_ebs_data_size" {
  description = "Size of the data EBS volume in GB."
  type        = number
  default     = 30

  validation {
    condition     = var.dtrack_ebs_data_size >= 10 && var.dtrack_ebs_data_size <= 1024
    error_message = "Data volume size must be between 10 and 1024 GB."
  }
}

variable "dtrack_ebs_data_throughput" {
  description = "The data EBS volume throughput in MiB/s."
  type        = number
  default     = 200
}

variable "dtrack_ebs_data_snapshot_id" {
  description = "Snapshot ID to use for the data EBS volume."
  type        = string
  default     = null
}

variable "dtrack_security_group_ingress_cidr_blocks" {
  description = "List of trusted IPv4 CIDR blocks allowed for ingress. Public ingress from 0.0.0.0/0 is rejected."
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition = alltrue([
      for cidr in var.dtrack_security_group_ingress_cidr_blocks :
      can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "Each IPv4 ingress entry must be a valid CIDR block and must not be 0.0.0.0/0."
  }
}

variable "dtrack_security_group_ingress_ipv6_cidr_blocks" {
  description = "List of trusted IPv6 CIDR blocks allowed for ingress. Public ingress from ::/0 is rejected."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.dtrack_security_group_ingress_ipv6_cidr_blocks :
      can(regex("^([0-9a-fA-F:]+)/(?:\\d|[1-9]\\d|1[01]\\d|12[0-8])$", cidr)) && cidr != "::/0"
    ])
    error_message = "Each IPv6 ingress entry must be a valid CIDR block and must not be ::/0."
  }
}

variable "dtrack_security_group_ingress_rules" {
  description = "List of ingress rules for the security group."
  type        = list(string)
  default     = ["https-443-tcp"]
}

variable "dtrack_security_group_egress_rules" {
  description = "List of egress rules for the security group."
  type        = list(string)
  default     = ["https-443-tcp"]
}

variable "dtrack_eip_create" {
  description = "Specifies whether a public EIP will be created and associated with the instance."
  type        = bool
  default     = false
}
