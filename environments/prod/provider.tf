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
