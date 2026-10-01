# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_data "aws_subnet" {
    defaults = { id = "subnet-0123456789abcdef0" }
  }
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0" }
  }
  mock_data "aws_availability_zones" {
    defaults = { names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"] }
  }
}

variables {
  key_pair_create         = false
  dtrack_ebs_data_create  = false
  dtrack_eip_create       = false
}

run "invalid_region" {
  command = plan
  variables { region = "us-east-1" }
  expect_failures = [var.region]
}

run "invalid_instance_type" {
  command = plan
  variables { dtrack_ec2_instance_type = "m5.large" }
  expect_failures = [var.dtrack_ec2_instance_type]
}

run "invalid_ebs_root_size" {
  command = plan
  variables { dtrack_ebs_root_size = 7 }
  expect_failures = [var.dtrack_ebs_root_size]
}

run "invalid_ebs_data_size" {
  command = plan
  variables { dtrack_ebs_data_size = 9 }
  expect_failures = [var.dtrack_ebs_data_size]
}

run "invalid_tags" {
  command = plan
  variables { tags = {} }
  expect_failures = [var.tags]
}

run "reject_public_ipv4_ingress" {
  command = plan
  variables { dtrack_security_group_ingress_cidr_blocks = ["0.0.0.0/0"] }
  expect_failures = [var.dtrack_security_group_ingress_cidr_blocks]
}

run "reject_public_ipv6_ingress" {
  command = plan
  variables { dtrack_security_group_ingress_ipv6_cidr_blocks = ["::/0"] }
  expect_failures = [var.dtrack_security_group_ingress_ipv6_cidr_blocks]
}
