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
  target = module.component_analysis
  outputs = {
    ec2_instance_id = "i-0123456789abcdef0"
  }
}

variables {
  key_pair_create = false
}

run "stage_valid_defaults" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }
}

run "stage_invalid_instance_type" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    dtrack_ec2_instance_type = "m5.large"
  }

  expect_failures = [var.dtrack_ec2_instance_type]
}

run "stage_invalid_root_size" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    dtrack_ebs_root_size = -1
  }

  expect_failures = [var.dtrack_ebs_root_size]
}

run "stage_invalid_data_size" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    dtrack_ebs_data_size = -1
  }

  expect_failures = [var.dtrack_ebs_data_size]
}

run "stage_empty_tags" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    tags = {}
  }

  expect_failures = [var.tags]
}

run "stage_public_ipv4" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    dtrack_security_group_ingress_cidr_blocks = ["10.0.0.1/0"]
  }

  expect_failures = [var.dtrack_security_group_ingress_cidr_blocks]
}

run "stage_expanded_public_ipv6" {
  command = plan

  module {
    source = "./environments/stage/ec2"
  }

  variables {
    dtrack_security_group_ingress_ipv6_cidr_blocks = ["0:0:0:0:0:0:0:0/0"]
  }

  expect_failures = [var.dtrack_security_group_ingress_ipv6_cidr_blocks]
}

run "prod_valid_defaults" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }
}

run "prod_invalid_instance_type" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    dtrack_ec2_instance_type = "m5.large"
  }

  expect_failures = [var.dtrack_ec2_instance_type]
}

run "prod_invalid_root_size" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    dtrack_ebs_root_size = -1
  }

  expect_failures = [var.dtrack_ebs_root_size]
}

run "prod_invalid_data_size" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    dtrack_ebs_data_size = -1
  }

  expect_failures = [var.dtrack_ebs_data_size]
}

run "prod_empty_tags" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    tags = {}
  }

  expect_failures = [var.tags]
}

run "prod_public_ipv4" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    dtrack_security_group_ingress_cidr_blocks = ["10.0.0.1/0"]
  }

  expect_failures = [var.dtrack_security_group_ingress_cidr_blocks]
}

run "prod_expanded_public_ipv6" {
  command = plan

  module {
    source = "./environments/prod/ec2"
  }

  variables {
    dtrack_security_group_ingress_ipv6_cidr_blocks = ["0:0:0:0:0:0:0:0/0"]
  }

  expect_failures = [var.dtrack_security_group_ingress_ipv6_cidr_blocks]
}
