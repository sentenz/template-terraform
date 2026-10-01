# SPDX-License-Identifier: Apache-2.0

locals {
  addons_default = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      # Example of passing configuration values to the CNI addon if needed:
      # configuration_values = jsonencode({
      #   env = { ENABLE_PREFIX_DELEGATION = "true" }
      # })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }
}
