# SPDX-License-Identifier: Apache-2.0

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  count = var.vpc_create ? 1 : 0

  name               = local.vpc_name
  cidr               = var.vpc_cidr
  private_subnets    = var.vpc_private_subnets
  public_subnets     = var.vpc_public_subnets
  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway
  azs                = local.vpc_azs

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  subnet_ids = var.vpc_create ? module.vpc[0].private_subnets : var.subnet_ids
  vpc_id     = var.vpc_create ? module.vpc[0].vpc_id : var.vpc_id

  create_kms_key         = var.create_cluster_kms_key
  enabled_log_types      = var.enabled_log_types
  kms_key_administrators = var.kms_key_administrators

  addons = merge(local.addons_default, var.extra_cluster_addons)

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  eks_managed_node_groups = merge(
    {
      default = {
        ami_type       = "AL2023_x86_64_STANDARD"
        capacity_type  = var.default_mng_capacity_type
        desired_size   = var.default_mng_desired_size
        disk_size      = 40
        instance_types = var.default_mng_instance_types
        labels         = { pool = "default" }
        max_size       = var.default_mng_max_size
        min_size       = var.default_mng_min_size
        subnet_ids     = var.node_subnet_ids != null ? var.node_subnet_ids : (var.vpc_create ? module.vpc[0].private_subnets : var.subnet_ids)
        taints         = []
      }
    },
    var.extra_managed_node_groups,
  )

  fargate_profiles = var.fargate_profiles

  tags = var.tags
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.8.1"

  associations = {
    for key, association in var.pod_identity_associations :
    key => merge(association, {
      cluster_name = module.eks.cluster_name
    })
  }

  tags = var.tags
}
