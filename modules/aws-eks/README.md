# AWS EKS module

This module provisions an Amazon EKS cluster, managed node groups, optional Fargate profiles, EKS-managed add-ons, optional VPC infrastructure, and AWS Pod Identity associations.

## Requirements

| Component | Version |
| --- | --- |
| Terraform | `~> 1.10.0` |
| AWS provider | `>= 6.13, < 7.0` |

## Child modules

| Module | Source | Version |
| --- | --- | --- |
| VPC | `terraform-aws-modules/vpc/aws` | `6.6.1` |
| EKS | `terraform-aws-modules/eks/aws` | `21.24.0` |
| Pod Identity | `terraform-aws-modules/eks-pod-identity/aws` | `2.8.1` |

## Usage

```hcl
module "platform" {
  source = "../../modules/aws-eks"

  name               = "platform-stage"
  kubernetes_version = "1.33"

  vpc_create = false
  vpc_id     = data.aws_vpc.platform.id
  subnet_ids = data.aws_subnets.private.ids

  endpoint_private_access = true
  endpoint_public_access  = false

  enable_cluster_creator_admin_permissions = false
  access_entries = {
    platform_admin = {
      principal_arn = "arn:aws:iam::123456789012:role/platform-admin"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  default_mng_instance_types = ["m6i.large"]
  default_mng_min_size       = 2
  default_mng_desired_size   = 3
  default_mng_max_size       = 6

  pod_identity_associations = {
    external_dns = {
      namespace       = "kube-system"
      service_account = "external-dns"
      role_name       = "platform-stage-external-dns"
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess",
      ]
    }
  }

  tags = {
    Name        = "Platform EKS"
    Environment = "Stage"
    Terraform   = "true"
    Owner       = "Platform"
  }
}
```

## Endpoint and access safety

Private endpoint access is enabled by default and public endpoint access is disabled.

When `endpoint_public_access = true`, `endpoint_public_access_cidrs` must contain at least one valid, restricted IPv4 CIDR. `0.0.0.0/0` is rejected.

`enable_cluster_creator_admin_permissions` defaults to `false`. Long-lived environments should use explicit `access_entries`. Existing clusters that currently depend on creator administration must add and verify replacement access entries in a reviewed plan before disabling the compatibility setting.

## Important inputs

| Name | Description | Default |
| --- | --- | --- |
| `name` | EKS cluster name | `aws-eks` |
| `kubernetes_version` | Kubernetes major and minor version | `1.33` |
| `vpc_create` | Create a VPC inside the module | `false` |
| `vpc_id` | Existing VPC ID when `vpc_create = false` | `null` |
| `subnet_ids` | At least two existing subnet IDs | `null` |
| `endpoint_private_access` | Enable private API endpoint access | `true` |
| `endpoint_public_access` | Enable public API endpoint access | `false` |
| `endpoint_public_access_cidrs` | Restricted public endpoint CIDRs | `null` |
| `enabled_log_types` | EKS control-plane logs | all supported types |
| `create_cluster_kms_key` | Create a KMS key for secrets encryption | `true` |
| `access_entries` | Explicit EKS principals and policy associations | `{}` |
| `enable_cluster_creator_admin_permissions` | Grant the Terraform caller cluster admin | `false` |
| `extra_managed_node_groups` | Additional managed node groups | `{}` |
| `fargate_profiles` | Optional Fargate profiles | `{}` |
| `pod_identity_associations` | Workload IAM roles and service-account associations | `{}` |

The complete typed contract is defined in [`variables.tf`](./variables.tf).

## Outputs

| Name | Description |
| --- | --- |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_ca_certificate` | Base64-encoded cluster CA data |
| `cluster_version` | Kubernetes version |
| `oidc_provider_arn` | Cluster OIDC provider ARN |
| `node_group_role_arns` | Managed node-group IAM role ARNs |

## Validation

```bash
terraform fmt -check -diff -recursive
terraform -chdir=modules/aws-eks init -backend=false
terraform -chdir=modules/aws-eks validate
terraform -chdir=modules/aws-eks test
```

Before applying changes to an existing cluster, create and review a saved state-backed plan. In particular, verify access-entry changes, node-group replacement, subnet topology, and any resource deletion before approval.
