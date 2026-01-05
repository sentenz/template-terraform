
# SPDX-License-Identifier: Apache-2.0

variable "region" {
  description = "The AWS region to  deploy resources."
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
}

variable "key_pair_create" {
  description = "Whether to create a new SSH key pair for EC2 access."
  type        = bool
  default     = true
}

variable "key_path" {
  description = "Path to the public key for SSH access."
  type        = string
  sensitive   = true
  default     = "~/.ssh/samsongroup_e_devops_service_sshkey.pub"

  validation {
    condition     = can(regex("^.*\\.pub$", var.key_path))
    error_message = "The key_path must be a valid path to a public key file ending with '.pub'."
  }
}

variable "dtrack_ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string
  default     = "t3.xlarge"
}

variable "dtrack_ebs_root_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 30
}

variable "dtrack_ebs_data_size" {
  description = "Size of the data EBS volume in GB."
  type        = number
  default     = 30
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
