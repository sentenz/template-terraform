# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "The name for resources."
  type        = string
  default     = "aws-ec2"
}

variable "tags" {
  description = "Global resource tags."
  type        = map(string)
  default = {
    Name        = "AWS EC2 Module"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

variable "key_pair_create" {
  description = "Whether to create a new SSH key pair for EC2 access."
  type        = bool
  default     = false
}

variable "key_path" {
  description = "Path to SSH public key file for SSH access."
  type        = string
  default     = null

  validation {
    condition = (
      var.key_pair_create == false
      || (
        try(length(var.key_path) > 0, false)
        && can(regex("^.*\\.pub$", var.key_path))
      )
    )
    error_message = "When key_pair_create is true, key_path must be provided and end with '.pub'."
  }

  sensitive = true
}

variable "vpc_create" {
  description = "Whether to create a new VPC."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of existing VPC to use when vpc_create is false."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_create || try(length(var.vpc_id) > 0, false)
    error_message = "vpc_id must be provided when vpc_create is false."
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "vpc_private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

variable "vpc_public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
  default     = ["192.168.101.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Whether to enable NAT gateway."
  type        = bool
  default     = true
}

variable "vpc_single_nat_gateway" {
  description = "Whether to use a single NAT gateway."
  type        = bool
  default     = true
}

variable "ami_most_recent" {
  description = "Use the most recent AMI from the list."
  type        = bool
  default     = true
}

variable "ami_owners" {
  description = "AMI Owners."
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_image_name" {
  description = "The name used to select Amazon Machine Images (AMIs)."
  type        = string
  default     = "name"
}

variable "ami_image_patterns" {
  description = "The AMI pattern to search for, e.g., Amazon Linux 2023 (AL2023) IDs."
  type        = list(string)
  default     = ["al2023-ami-2023*-x86_64"]
}

variable "ami_virtualization_name" {
  description = "The virtualization method used by the AMI."
  type        = string
  default     = "virtualization-type"
}

variable "ami_virtualization_types" {
  description = "The virtualization standard, e.g., Hardware Virtual Machine (HVM) used by Amazon EC2 instances."
  type        = list(string)
  default     = ["hvm"]
}

variable "ami_device_name" {
  description = "The root device type used by the AMI."
  type        = string
  default     = "root-device-type"
}

variable "ami_device_types" {
  description = "The root device type, typically EBS-backed for encryption support."
  type        = list(string)
  default     = ["ebs"]
}

variable "azs_state" {
  description = "Filter to retrieve availability zones in a specific state."
  type        = string
  default     = "available"
}

variable "security_group_description" {
  description = "The description of the security group."
  type        = string
  default     = "Security group for AWS EC2 Module."
}

variable "security_group_ingress_cidr_blocks" {
  description = "List of trusted IPv4 CIDR blocks allowed for ingress. Public ingress from 0.0.0.0/0 is rejected."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.security_group_ingress_cidr_blocks :
      can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "Each IPv4 ingress entry must be a valid CIDR block and must not be 0.0.0.0/0."
  }
}

variable "security_group_ingress_ipv6_cidr_blocks" {
  description = "List of trusted IPv6 CIDR blocks allowed for ingress. Public ingress from ::/0 is rejected."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.security_group_ingress_ipv6_cidr_blocks :
      can(cidrhost(cidr, 0)) && strcontains(cidr, ":") && cidr != "::/0"
    ])
    error_message = "Each IPv6 ingress entry must be a valid IPv6 CIDR block and must not be ::/0."
  }
}

variable "security_group_ingress_rules" {
  description = "Supported named ingress rule presets."
  type        = list(string)
  default     = ["https-443-tcp"]

  validation {
    condition = alltrue([
      for rule_name in var.security_group_ingress_rules :
      contains(["http-80-tcp", "https-443-tcp", "ssh-tcp"], rule_name)
    ])
    error_message = "security_group_ingress_rules supports only http-80-tcp, https-443-tcp, and ssh-tcp."
  }
}

variable "security_group_egress_rules" {
  description = "Supported named egress rule presets."
  type        = list(string)
  default     = ["https-443-tcp"]

  validation {
    condition = alltrue([
      for rule_name in var.security_group_egress_rules :
      contains(["http-80-tcp", "https-443-tcp", "ssh-tcp"], rule_name)
    ])
    error_message = "security_group_egress_rules supports only http-80-tcp, https-443-tcp, and ssh-tcp."
  }
}

variable "security_group_ingress_with_cidr_blocks" {
  description = "Ingress rules with one or more comma-separated trusted IPv4 or IPv6 CIDR blocks. Public ingress is rejected."
  type = list(object({
    cidr_blocks = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = []

  validation {
    condition = alltrue(flatten([
      for rule in var.security_group_ingress_with_cidr_blocks : [
        for cidr in split(",", rule.cidr_blocks) :
        length(trimspace(cidr)) > 0 &&
        can(cidrhost(trimspace(cidr), 0)) &&
        trimspace(cidr) != "0.0.0.0/0" &&
        trimspace(cidr) != "::/0"
      ]
    ]))
    error_message = "Every explicit ingress CIDR must be valid and must not be 0.0.0.0/0 or ::/0."
  }
}

variable "ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string
}

variable "ec2_subnet_id" {
  description = "The VPC subnet ID to launch in when vpc_create is false."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_create || try(length(var.ec2_subnet_id) > 0, false)
    error_message = "ec2_subnet_id must be provided when vpc_create is false."
  }
}

variable "ec2_ignore_ami_changes" {
  description = "Whether Terraform should ignore changes to the AMI ID. NOTE Changing this value will result in replacement of the instance."
  type        = bool
  default     = true
}

variable "eip_create" {
  description = "Specifies whether a public EIP will be created and associated with the instance."
  type        = bool
  default     = false
}

variable "ebs_enable_volume_tags" {
  description = "Whether to enable volume tags (if enabled it conflicts with `root_block_device` tags)."
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Whether the EC2 instance should be EBS-optimized."
  type        = bool
  default     = false
}

variable "ebs_root_encrypted" {
  description = "Specifies whether the root EBS volume will be encrypted."
  type        = bool
  default     = true
}

variable "ebs_root_throughput" {
  description = "The root EBS volume throughput in MiB/s."
  type        = number
  default     = 200
}

variable "ebs_root_iops" {
  description = "The root EBS volume IOPS (Input/Output Operations Per Second)."
  type        = number
  default     = 3000
}

variable "ebs_root_type" {
  description = "Type of the root EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_root_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 50
}

variable "ebs_data_create" {
  description = "Whether to create and attach a data EBS volume."
  type        = bool
  default     = false
}

variable "ebs_data_encrypted" {
  description = "Specifies whether the data EBS volume will be encrypted."
  type        = bool
  default     = true
}

variable "ebs_data_throughput" {
  description = "The data EBS volume throughput in MiB/s."
  type        = number
  default     = 200
}

variable "ebs_data_iops" {
  description = "The data EBS volume IOPS (Input/Output Operations Per Second)."
  type        = number
  default     = 3000
}

variable "ebs_data_type" {
  description = "Type of the data EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_data_size" {
  description = "Size of the data EBS volume in GB."
  type        = number
  default     = 50
}

variable "ebs_data_device_name" {
  description = "Logical device name for the data EBS volume attachment; names `/dev/sd[f-p]` map to NVMe `/dev/nvme*n*` device nodes. NOTE Do not use root names `/dev/sda`, `/dev/sda1`."
  type        = string
  default     = "/dev/sdf"
}

variable "ebs_data_snapshot_id" {
  description = "Snapshot ID to use for the data EBS volume."
  type        = string
  default     = null
}
