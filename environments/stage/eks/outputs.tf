# SPDX-License-Identifier: Apache-2.0

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate authority data for the EKS cluster."
  value       = local.cluster_ca_certificate
}

output "cluster_endpoint" {
  description = "Private EKS API server endpoint."
  value       = local.host
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = local.cluster_name
}
