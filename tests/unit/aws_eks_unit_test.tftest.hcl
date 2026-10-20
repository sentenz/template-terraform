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
  target = module.eks
  outputs = {
    cluster_name                       = "contract-test"
    cluster_endpoint                   = "https://example.invalid"
    cluster_certificate_authority_data = "dGVzdA=="
    cluster_version                    = "1.33"
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/example.invalid"
    eks_managed_node_groups            = {}
  }
}

override_module {
  target  = module.pod_identity
  outputs = {}
}

override_module {
  target = module.vpc
  outputs = {
    vpc_id          = "vpc-0123456789abcdef0"
    private_subnets = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  }
}

variables {
  name       = "contract-test"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
}

run "existing_network" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  assert {
    condition     = length(module.vpc) == 0 && output.cluster_name == "contract-test"
    error_message = "Existing-network mode must forward cluster outputs without creating a VPC."
  }
}

run "created_network" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    vpc_create = true
    vpc_id     = null
    subnet_ids = null
  }

  assert {
    condition     = length(module.vpc) == 1 && local.vpc_name == "contract-test_vpc"
    error_message = "Created-network mode must resolve the VPC name from the module name."
  }
}

run "missing_vpc" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    vpc_id = null
  }

  expect_failures = [var.vpc_id]
}

run "missing_subnets" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}

run "invalid_capacity" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_capacity_type = "INVALID"
  }

  expect_failures = [var.default_mng_capacity_type]
}

run "negative_minimum" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_min_size = -1
  }

  expect_failures = [var.default_mng_min_size]
}

run "fractional_minimum" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_min_size = 1.5
  }

  expect_failures = [var.default_mng_min_size]
}

run "desired_below_minimum" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_desired_size = 1
  }

  expect_failures = [var.default_mng_desired_size]
}

run "desired_above_maximum" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_desired_size = 7
  }

  expect_failures = [var.default_mng_desired_size]
}

run "fractional_desired" {
  command = plan

  module {
    source = "./modules/aws-eks"
  }

  variables {
    default_mng_desired_size = 2.5
  }

  expect_failures = [var.default_mng_desired_size]
}
