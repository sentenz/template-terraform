# SPDX-License-Identifier: Apache-2.0

# These tests exercise wrapper contracts. Upstream modules are overridden;
# provider API behavior is covered separately by opt-in integration tests.
mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }
}

mock_provider "tls" {}

override_module {
  target = module.ec2_instance
  outputs = {
    id         = "i-0123456789abcdef0"
    private_ip = "10.0.1.10"
    public_ip  = ""
    public_dns = ""
  }
}

override_module {
  target = module.security_group
  outputs = {
    security_group_id = "sg-0123456789abcdef0"
  }
}

override_module {
  target = module.vpc
  outputs = {
    vpc_id         = "vpc-0123456789abcdef0"
    public_subnets = ["subnet-0123456789abcdef0"]
  }
}

variables {
  name              = "contract-test"
  ec2_instance_type = "t3.small"
  vpc_id            = "vpc-0123456789abcdef0"
  ec2_subnet_id     = "subnet-0123456789abcdef0"
  key_pair_create   = false
  key_path          = null
  tags              = {}
}

run "existing_network_without_ssh_key" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  assert {
    condition     = length(module.key_pair) == 0 && length(module.vpc) == 0
    error_message = "Existing-network mode must not create a VPC or SSH key pair."
  }

  assert {
    condition     = output.ec2_instance_id == "i-0123456789abcdef0"
    error_message = "The wrapper must expose the child instance ID."
  }
}

run "created_network" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    vpc_create    = true
    vpc_id        = null
    ec2_subnet_id = null
  }

  assert {
    condition     = length(module.vpc) == 1 && local.vpc_name == "contract-test_vpc"
    error_message = "Created-network mode must select a named VPC without requiring existing IDs."
  }
}

run "trusted_ingress" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_cidr_blocks      = ["10.0.0.0/8", "192.168.0.0/16"]
    security_group_ingress_ipv6_cidr_blocks = ["2001:db8::/32"]
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "10.0.0.0/8, 192.168.0.0/16"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Trusted HTTPS clients"
    }]
  }
}

run "missing_vpc" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    vpc_id = null
  }

  expect_failures = [var.vpc_id]
}

run "missing_subnet" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    ec2_subnet_id = null
  }

  expect_failures = [var.ec2_subnet_id]
}

run "public_ipv4" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_cidr_blocks = ["0.0.0.0/0"]
  }

  expect_failures = [var.security_group_ingress_cidr_blocks]
}

run "noncanonical_public_ipv4" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_cidr_blocks = ["10.0.0.1/0"]
  }

  expect_failures = [var.security_group_ingress_cidr_blocks]
}

run "malformed_ipv4" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_cidr_blocks = ["not-a-cidr"]
  }

  expect_failures = [var.security_group_ingress_cidr_blocks]
}

run "public_ipv6" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_ipv6_cidr_blocks = ["::/0"]
  }

  expect_failures = [var.security_group_ingress_ipv6_cidr_blocks]
}

run "expanded_public_ipv6" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_ipv6_cidr_blocks = ["0:0:0:0:0:0:0:0/0"]
  }

  expect_failures = [var.security_group_ingress_ipv6_cidr_blocks]
}

run "malformed_ipv6" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_ipv6_cidr_blocks = ["::::/64"]
  }

  expect_failures = [var.security_group_ingress_ipv6_cidr_blocks]
}

run "ipv4_in_ipv6" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_ipv6_cidr_blocks = ["10.0.0.0/8"]
  }

  expect_failures = [var.security_group_ingress_ipv6_cidr_blocks]
}

run "public_tuple" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}

run "mixed_public_tuple" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "10.0.0.0/8, 0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}

run "host_bits_public_tuple" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "10.0.0.1/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}

run "malformed_tuple" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "10.0.0.0/8, bad"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}

run "ipv6_tuple" {
  command = plan

  module {
    source = "./modules/aws-ec2"
  }

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "::/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}
