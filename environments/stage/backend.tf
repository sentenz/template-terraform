# SPDX-License-Identifier: Apache-2.0

terraform {
  backend "s3" {
    # NOTE The S3 Bucket backend to store the terraform state is created manually via the AWS Dashboard (ClickOps).
    # Reference the `bucket` name according to the AWS S3 Dashboard, e.g. `terraform-state-stage`.
    bucket       = "tf-state-e-dev"
    key          = "stage/component-analysis/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
    profile      = "stage"
  }
}
