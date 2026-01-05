# SPDX-License-Identifier: Apache-2.0

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Project = "DevOps"
    }
  }
}

# provider "helm" {
#   kubernetes = {
#     host                   = local.host
#     cluster_ca_certificate = base64decode(local.cluster_ca_certificate)

#     exec = {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       # This requires the awscli to be installed locally where Terraform is executed
#       args = ["eks", "get-token", "--cluster-name", local.cluster_name]
#     }
#   }
# }

# NOTE If the execution environment cannot install `awscli`, use the AWS data source for a bearer token.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
