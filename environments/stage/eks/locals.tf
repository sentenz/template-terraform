# SPDX-License-Identifier: Apache-2.0

locals {
  host                   = module.k8s.cluster_endpoint
  cluster_ca_certificate = module.k8s.cluster_ca_certificate
  cluster_name           = module.k8s.cluster_name
}
