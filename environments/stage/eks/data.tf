# SPDX-License-Identifier: Apache-2.0

# NOTE If the execution environment cannot install `awscli`, use the AWS data source for a bearer token.

data "aws_eks_cluster" "this" {
  name       = module.k8s.cluster_name
  depends_on = [module.k8s]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.k8s.cluster_name
  depends_on = [module.k8s]
}
