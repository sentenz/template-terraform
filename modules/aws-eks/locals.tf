# SPDX-License-Identifier: Apache-2.0

locals {
  vpc_az_count = max(length(var.vpc_private_subnets), length(var.vpc_public_subnets))
  vpc_azs = var.vpc_create ? slice(
    data.aws_availability_zones.available[0].names,
    0,
    local.vpc_az_count,
  ) : []

  addons_default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }
}
