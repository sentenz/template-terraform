# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  override_during = plan
}

variables {
  name       = "contract-test"
  vpc_create = false
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
  ]

  endpoint_private_access = true
  endpoint_public_access  = false

  enable_cluster_creator_admin_permissions = false
  access_entries = {
    platform = {
      principal_arn = "arn:aws:iam::123456789012:role/eks-platform"
      policy_associations = {
        namespace_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["platform"]
          }
        }
      }
    }
  }
}

run "accepts_private_endpoint_and_explicit_access" {
  command = plan

  assert {
    condition     = var.endpoint_private_access && !var.endpoint_public_access
    error_message = "The secure default must retain private-only endpoint access."
  }

  assert {
    condition     = var.access_entries.platform.policy_associations.namespace_admin.access_scope.namespaces == ["platform"]
    error_message = "Namespace-scoped access entries must retain their namespace list."
  }
}

run "rejects_public_endpoint_without_restricted_cidrs" {
  command = plan

  variables {
    endpoint_public_access       = true
    endpoint_public_access_cidrs = null
  }

  expect_failures = [var.endpoint_public_access_cidrs]
}

run "rejects_disabled_cluster_endpoints" {
  command = plan

  variables {
    endpoint_private_access = false
    endpoint_public_access  = false
  }

  expect_failures = [var.endpoint_private_access]
}

run "rejects_invalid_default_node_group_bounds" {
  command = plan

  variables {
    default_mng_min_size     = 3
    default_mng_desired_size = 2
    default_mng_max_size     = 6
  }

  expect_failures = [var.default_mng_desired_size]
}

run "rejects_invalid_extra_node_group_bounds" {
  command = plan

  variables {
    extra_managed_node_groups = {
      invalid = {
        instance_types = ["m6i.large"]
        min_size       = 2
        desired_size   = 1
        max_size       = 3
      }
    }
  }

  expect_failures = [var.extra_managed_node_groups]
}

run "rejects_invalid_access_scope" {
  command = plan

  variables {
    access_entries = {
      invalid = {
        principal_arn = "arn:aws:iam::123456789012:role/eks-invalid"
        policy_associations = {
          invalid = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
            access_scope = {
              type = "invalid"
            }
          }
        }
      }
    }
  }

  expect_failures = [var.access_entries]
}
