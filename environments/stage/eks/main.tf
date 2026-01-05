# SPDX-License-Identifier: Apache-2.0

data "aws_availability_zones" "available" {}

###############################################################################
# Networking (terraform-aws-modules/vpc/aws) — simple 3AZ private+public
###############################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${var.name}-vpc"
  cidr = "10.42.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.42.0.0/19", "10.42.32.0/19", "10.42.64.0/19"]
  public_subnets  = ["10.42.96.0/20", "10.42.112.0/20", "10.42.128.0/20"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

module "k8s" {
  source = "../../../modules/aws-eks"

  name = var.name

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Expose the API privately by default
  endpoint_public_access = false

  # Default node group tuned for typical control/data workloads
  default_mng_instance_types = ["m6i.large"]
  default_mng_min_size       = 2
  default_mng_desired_size   = 3
  default_mng_max_size       = 6

  # Example: add an extra SPOT pool for batch/CI
  extra_managed_node_groups = {
    spot-ci = {
      instance_types = ["m6i.large", "m7i-flex.large"]
      capacity_type  = "SPOT"
      min_size       = 0
      desired_size   = 0
      max_size       = 10
      labels         = { pool = "spot-ci" }
      taints = [{
        key    = "workload"
        value  = "ci"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  # Add-ons beyond defaults if required
  extra_cluster_addons = {
    # Example override: keep most recent explicitly
    coredns = { most_recent = true }
  }

  # Pod Identity for an example workload: external-dns
  pod_identity_associations = {
    external-dns = {
      namespace       = "kube-system"
      service_account = "external-dns"
      role_name       = "${var.name}-external-dns"
      # Prefer tight, scoped policies in production; this is illustrative.
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

###############################################################################
# Optional: seed the SA for external-dns so association has a target
###############################################################################
resource "kubernetes_namespace" "kube_system" {
  metadata { name = "kube-system" }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    labels    = { app = "external-dns" }
  }
  automount_service_account_token = true
}
