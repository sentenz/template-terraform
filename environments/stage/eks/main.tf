# SPDX-License-Identifier: Apache-2.0

data "aws_availability_zones" "available" {}

###############################################################################
# Networking (terraform-aws-modules/vpc/aws) — simple 3AZ private+public
###############################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${var.name}-vpc"
  cidr = "10.42.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.42.0.0/19", "10.42.32.0/19", "10.42.64.0/19"]
  public_subnets  = ["10.42.96.0/20", "10.42.112.0/20", "10.42.128.0/20"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  tags = var.tags
}

module "k8s" {
  source = "../../../modules/aws-eks"

  name = var.name

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  endpoint_private_access = true
  endpoint_public_access  = false

  # Explicit compatibility choice. Replace with managed EKS access entries before disabling.
  enable_cluster_creator_admin_permissions = true

  default_mng_desired_size   = 3
  default_mng_instance_types = ["m6i.large"]
  default_mng_max_size       = 6
  default_mng_min_size       = 2

  extra_managed_node_groups = {
    spot-ci = {
      capacity_type  = "SPOT"
      desired_size   = 0
      instance_types = ["m6i.large", "m7i-flex.large"]
      labels         = { pool = "spot-ci" }
      max_size       = 10
      min_size       = 0
      taints = [{
        key    = "workload"
        value  = "ci"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  extra_cluster_addons = {
    coredns = { most_recent = true }
  }

  pod_identity_associations = {
    external-dns = {
      namespace       = "kube-system"
      service_account = "external-dns"
      role_name       = "${var.name}-external-dns"
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess"
      ]
      policies_json = [
        jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Effect   = "Allow"
            Action   = ["route53:ChangeResourceRecordSets"]
            Resource = "arn:aws:route53:::hostedzone/*"
          }]
        })
      ]
    }
  }

  tags = var.tags
}
