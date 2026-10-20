# SPDX-License-Identifier: Apache-2.0

# Opt-in: creates and destroys real AWS resources in an existing test network.
# Set TF_VAR_vpc_id and TF_VAR_ec2_subnet_id and use sandbox AWS credentials.
provider "aws" {
  region = "eu-central-1"
}

variables {
  name              = "terraform-ec2-integration"
  ec2_instance_type = "t3.small"
  key_pair_create   = false
  vpc_create        = false
  ebs_data_create   = false
  eip_create        = false
  tags = {
    Name        = "Terraform EC2 Integration"
    Environment = "Test"
    Terraform   = "true"
  }
}

run "create_ec2_in_existing_network" {
  command = apply

  module {
    source = "./modules/aws-ec2"
  }

  assert {
    condition     = can(regex("^i-[0-9a-f]+$", output.ec2_instance_id))
    error_message = "The module must return the created EC2 instance ID."
  }

  assert {
    condition     = can(cidrhost("${output.ec2_private_ip}/32", 0))
    error_message = "The instance must receive a private IPv4 address."
  }
}
