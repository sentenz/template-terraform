# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "The name for resources."
  type        = string
  default     = "aws-ec2"
}

variable "tags" {
  description = "A map of tags to add to all resources."
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
  sensitive   = true
  default     = null
}

variable "vpc_create" {
  description = "Whether to create a new VPC."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of existing VPC to use."
  type        = string
  default     = null
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

variable "sg_description" {
  description = "The description of the security group."
  type        = string
  default     = "Security group for AWS EC2 Module."
}

variable "sg_ingress_cidr_blocks" {
  description = "List of IPv4 CIDR blocks allowed for ingress, restricted to trusted IPs."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "sg_ingress_ipv6_cidr_blocks" {
  description = "List of IPv6 CIDR blocks allowed for ingress, restricted to trusted IPv6 ranges."
  type        = list(string)
  default     = []
}

variable "sg_ingress_rules" {
  description = "List of ingress rules for the security group for Least Privilege."
  type        = list(string)
  default     = ["https-443-tcp"]
}

variable "sg_egress_rules" {
  description = "List of egress rules for the security group for Least Privilege."
  type        = list(string)
  default     = ["https-443-tcp"]
}

variable "sg_ingress_with_cidr_blocks" {
  description = "List of ingress rules with specific CIDR blocks, restricted to trusted IPs."
  type = list(object({
    cidr_blocks = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = [
    {
      cidr_blocks = "10.0.0.0/16"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "HTTP access on port 8080 for internal use only."
    },
    {
      cidr_blocks = "10.0.0.0/16"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      description = "HTTPS access on port 8443 for internal use only."
    }
  ]
}

variable "ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string
}

variable "ec2_subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type        = string
  default     = null
}

variable "ec2_ignore_ami_changes" {
  description = "Whether Terraform should ignore changes to the AMI ID. NOTE Changing this value will result in the replacement of the instance."
  type        = bool
  default     = true
}

variable "eip_create" {
  description = "Specifies whether a public EIP will be created and associated with the instance."
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

variable "ebs_root_volume_type" {
  description = "Type of the root EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 50
}

variable "ebs_root_enable_tags" {
  description = "Whether to enable tags for the root EBS volume."
  type        = bool
  default     = false
}

variable "ebs_data_create" {
  description = "Whether to create and attach an data EBS volume."
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

variable "ebs_data_volume_type" {
  description = "Type of the data EBS volume."
  type        = string
  default     = "gp3"
}

variable "ebs_data_volume_size" {
  description = "Size of the data EBS volume in GB."
  type        = number
  default     = 50
}

variable "ebs_data_device_name" {
  description = "The device name for the additional EBS volume attachment."
  type        = string
  default     = "/dev/sdh"
}
