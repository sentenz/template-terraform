# SPDX-License-Identifier: Apache-2.0

data "aws_ami" "machine" {
  most_recent = var.ami_most_recent
  owners      = var.ami_owners

  filter {
    name   = var.ami_image_name
    values = var.ami_image_patterns
  }

  filter {
    name   = var.ami_virtualization_name
    values = var.ami_virtualization_types
  }

  filter {
    name   = var.ami_device_name
    values = var.ami_device_types
  }
}

data "aws_availability_zones" "available" {
  count = var.vpc_create ? 1 : 0

  state = var.azs_state
}
