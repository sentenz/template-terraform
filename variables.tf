# SPDX-License-Identifier: Apache-2.0

variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = contains(["eu-west-1", "eu-central-1"], var.aws_region)
    error_message = "The AWS region must be one of the following: eu-west-1, eu-central-1."
  }
}

variable "key_path" {
  description = "Path to the public key for SSH access."
  type        = string
  sensitive   = true
  default     = "~/.ssh/aws.pub"

  validation {
    condition     = can(regex("^.*\\.pub$", var.key_path))
    error_message = "The key_path must be a valid path to a public key file ending with '.pub'."
  }
}

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)

  validation {
    condition     = length(var.tags) > 0
    error_message = "Tags must not be empty."
  }
}

variable "dtrack_name" {
  description = "The name for resources."
  type        = string
  default     = "dependency-track"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.dtrack_name))
    error_message = "Resource name can only include alphanumeric characters, dashes (-), or underscores (_)."
  }
}

variable "dtrack_ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string

  validation {
    condition     = contains(["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"], var.dtrack_ec2_instance_type)
    error_message = "EC2 instance type must be one of t3.nano, t3.micro, t3.small, t3.medium, t3.large, t3.xlarge, or t3.2xlarge."
  }
}

variable "dtrack_sg_ingress_cidr_blocks" {
  description = "List of IPv4 CIDR blocks allowed for ingress, e.g., `0.0.0.0/0` refers to the entire IPv4 address space."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.dtrack_sg_ingress_cidr_blocks : can(regex("^(\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$", cidr))])
    error_message = "Each CIDR block must be a valid IPv4 CIDR (e.g., '0.0.0.0/0')."
  }
}

variable "dtrack_sg_ingress_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed for ingress, e.g., `::/0` refers to the entire IPv6 address space."
  type        = list(string)
  default     = ["::/0"]

  # TODO(sentenz) Modify IPv6 CIDR regex pattern
  # validation {
  #   condition     = alltrue([for cidr in var.dtrack_sg_ingress_ipv6_cidr_blocks : can(regex("^([a-fA-F0-9:]+:+)+[a-fA-F0-9]+/[0-9]{1,3}$", cidr))])
  #   error_message = "Each CIDR block must be a valid IPv6 CIDR (e.g., '::/0')."
  # }
}

variable "dtrack_sg_ingress_rules" {
  description = "List of ingress rules for the security group."
  type        = list(string)
  default     = ["http-80-tcp", "https-443-tcp", "ssh-tcp", "all-icmp"]

  validation {
    condition     = length(var.dtrack_sg_ingress_rules) > 0
    error_message = "At least one ingress rule must be specified."
  }
}

variable "dtrack_sg_egress_rules" {
  description = "List of egress rules for the security group."
  type        = list(string)
  default     = ["all-all"]

  validation {
    condition     = length(var.dtrack_sg_egress_rules) > 0
    error_message = "At least one egress rule must be specified."
  }
}

variable "dtrack_sg_ingress_with_cidr_blocks" {
  description = "List of ingress rules with specific CIDR blocks."
  type = list(object({
    cidr_blocks = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = [
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Inbound traffic for dtrack-frontend on port 8080."
    },
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 8081
      to_port     = 8081
      protocol    = "tcp"
      description = "Inbound traffic for dtrack-apiserver on port 8081."
    }
  ]

  validation {
    condition = alltrue([
      for rule in var.dtrack_sg_ingress_with_cidr_blocks :
      rule.from_port <= rule.to_port && rule.from_port >= 1024 && rule.to_port <= 65535
    ])
    error_message = "Ingress rules must use unprivileged ports (1024-65535) for both 'from_port' and 'to_port'."
  }
}

variable "dtrack_eip_create" {
  description = "Specifies whether a public EIP will be created and associated with the instance."
  type        = bool
  default     = true
}

variable "dtrack_ebs_data_create" {
  description = "Whether to create and attach a data EBS volume."
  type        = bool
  default     = true
}

variable "dtrack_ebs_root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number

  validation {
    condition     = var.dtrack_ebs_root_volume_size >= 8 && var.dtrack_ebs_root_volume_size <= 64
    error_message = "Root volume size must be between 8 and 64 GB."
  }
}

variable "dtrack_ebs_data_volume_size" {
  description = "Size of the data EBS volume in GB."
  type        = number

  validation {
    condition     = var.dtrack_ebs_data_volume_size >= 10 && var.dtrack_ebs_data_volume_size <= 128
    error_message = "Data volume size must be between 10 and 128 GB."
  }
}
