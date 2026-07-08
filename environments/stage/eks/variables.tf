# SPDX-License-Identifier: Apache-2.0

variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = contains(["eu-west-1", "eu-central-1"], var.region)
    error_message = "The AWS region must be one of the following: eu-west-1, eu-central-1."
  }
}

variable "profile" {
  description = "The AWS credentials stored in `~/.aws/credentials` under a specific profile."
  type        = string
  default     = "stage"
}

variable "tags" {
  description = "Global resource tags."
  type        = map(string)
  default = {
    Name        = "Component Analysis"
    Terraform   = "true"
    Environment = "Stage"
    Owner       = "DevOps"
  }

  validation {
    condition     = length(var.tags) > 0
    error_message = "Tags must not be empty."
  }
}

variable "name" {
  description = "The EKS cluster name."
  type        = string
  default     = "k8s"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "The cluster name can only include alphanumeric characters, dashes (-), or underscores (_)."
  }
}
