
# SPDX-License-Identifier: Apache-2.0

variable "tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "Dev"
    Project     = "Internal Developer Platform (IDP)"
    Owner       = "DevOps"
  }
}

variable "dtrack_ec2_instance_type" {
  description = "The type to provide an EC2 instance resource."
  type        = string
  default     = "t3.nano"
}

variable "dtrack_ebs_root_volume_size" {
  description = "Size of the root EBS volume in GB."
  type        = number
  default     = 10
}

variable "dtrack_ebs_data_volume_size" {
  description = "Size of the data EBS volume in GB."
  type        = number
  default     = 10
}
