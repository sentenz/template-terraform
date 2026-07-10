# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  override_during = plan

  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

variables {
  name            = "contract-test"
  key_pair_create = false
  vpc_create      = false
  vpc_id          = "vpc-0123456789abcdef0"

  security_group_ingress_cidr_blocks      = ["10.0.0.0/16"]
  security_group_ingress_ipv6_cidr_blocks = []
  security_group_ingress_rules            = ["https-443-tcp"]
  security_group_egress_rules             = ["https-443-tcp"]
  security_group_ingress_with_cidr_blocks = []

  ec2_instance_type = "t3.micro"
  ec2_subnet_id     = "subnet-0123456789abcdef0"
  ebs_data_create   = false
  eip_create        = false
}

run "accepts_supported_rule_presets" {
  command = plan

  assert {
    condition     = local.security_group_ingress_rules["https-443-tcp|ipv4|10.0.0.0/16"].from_port == 443
    error_message = "The HTTPS preset must resolve to TCP port 443."
  }
}

run "rejects_public_cidr_in_comma_separated_rule" {
  command = plan

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "10.0.0.0/16,0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Invalid mixed ingress"
    }]
  }

  expect_failures = [var.security_group_ingress_with_cidr_blocks]
}

run "classifies_explicit_ipv6_cidr" {
  command = plan

  variables {
    security_group_ingress_with_cidr_blocks = [{
      cidr_blocks = "2001:db8::/64"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Trusted IPv6 ingress"
    }]
  }

  assert {
    condition = (
      local.security_group_ingress_explicit_rules["explicit-0|2001:db8::/64"].cidr_ipv4 == null &&
      local.security_group_ingress_explicit_rules["explicit-0|2001:db8::/64"].cidr_ipv6 == "2001:db8::/64"
    )
    error_message = "Explicit IPv6 CIDRs must populate cidr_ipv6 only."
  }
}

run "rejects_unsupported_ingress_preset" {
  command = plan

  variables {
    security_group_ingress_rules = ["rdp-tcp"]
  }

  expect_failures = [var.security_group_ingress_rules]
}

run "rejects_unsupported_egress_preset" {
  command = plan

  variables {
    security_group_egress_rules = ["all-all"]
  }

  expect_failures = [var.security_group_egress_rules]
}
