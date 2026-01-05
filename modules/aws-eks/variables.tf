# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "The EKS cluster name."
  type        = string
  default     = "aws-eks"
}

variable "tags" {
  description = "Global resource tags."
  type        = map(string)
  default = {
    Name        = "AWS EKS Module"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

variable "ami_most_recent" {
  description = "Use the most recent AMI from the list."
  type        = bool
  default     = true
}

variable "ami_owners" {
  description = "AMI Owners."
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_image_name" {
  description = "The name used to select Amazon Machine Images (AMIs)."
  type        = string
  default     = "name"
}

variable "ami_image_patterns" {
  description = "The AMI pattern to search for, e.g., Amazon Linux 2023 (AL2023) IDs."
  type        = list(string)
  default     = ["al2023-ami-2023*-x86_64"]
}

variable "ami_virtualization_name" {
  description = "The virtualization method used by the AMI."
  type        = string
  default     = "virtualization-type"
}

variable "ami_virtualization_types" {
  description = "The virtualization standard, e.g., Hardware Virtual Machine (HVM) used by Amazon EC2 instances."
  type        = list(string)
  default     = ["hvm"]
}

variable "ami_device_name" {
  description = "The root device type used by the AMI."
  type        = string
  default     = "root-device-type"
}

variable "ami_device_types" {
  description = "The root device type, typically EBS-backed for encryption support."
  type        = list(string)
  default     = ["ebs"]
}

variable "azs_state" {
  description = "Filter to retrieve availability zones in a specific state."
  type        = string
  default     = "available"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane version."
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "VPC ID for the cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for EKS control plane & default node groups (usually private)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Override subnets for node groups, defaults to `var.subnet_ids`."
  type        = list(string)
  default     = null
}

variable "endpoint_public_access" {
  description = "Expose the cluster endpoint publicly."
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Expose the cluster endpoint privately."
  type        = bool
  default     = true
}

variable "cluster_enabled_log_types" {
  description = "EKS control plane log types."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "create_cluster_kms_key" {
  description = "Create a KMS key for secrets encryption."
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "Principals with admin access to the created KMS key."
  type        = list(string)
  default     = []
}

variable "default_mng_instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}

variable "default_mng_min_size" {
  type    = number
  default = 2
}

variable "default_mng_desired_size" {
  type    = number
  default = 3
}

variable "default_mng_max_size" {
  type    = number
  default = 6
}

variable "default_mng_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "extra_managed_node_groups" {
  description = "Additional managed node groups to merge."
  type = map(object({
    ami_type       = optional(string, "AL2_x86_64")
    instance_types = list(string)
    min_size       = number
    desired_size   = number
    max_size       = number
    subnet_ids     = optional(list(string))
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    disk_size = optional(number, 40)
  }))
  default = {}
}

variable "fargate_profiles" {
  description = "Optional Fargate profiles."
  type = map(object({
    name                   = string
    selectors              = list(object({ namespace = string, labels = optional(map(string), {}) }))
    subnet_ids             = optional(list(string))
    pod_execution_role_arn = optional(string)
    tags                   = optional(map(string), {})
  }))
  default = {}
}

variable "extra_cluster_addons" {
  description = "Extra/override cluster addons map to merge with defaults."
  type = map(object({
    most_recent              = optional(bool, true)
    resolve_conflicts        = optional(string)
    configuration_values     = optional(string) # JSON
    preserve                 = optional(bool)
    service_account_role_arn = optional(string)
  }))
  default = {}
}

# Pod Identity association schema per service account
variable "pod_identity_associations" {
  description = <<-EOT
    Map of associations. Each entry:
    {
      namespace       = "ns"
      service_account = "sa"
      role_name       = "role-name"   # IAM role will be created
      policy_arns     = optional(list(string), [])
      policies_json   = optional(list(string), []) # JSON policy docs
      tags            = optional(map(string), {})
    }
  EOT
  type = map(object({
    namespace       = string
    service_account = string
    role_name       = string
    policy_arns     = optional(list(string), [])
    policies_json   = optional(list(string), [])
    tags            = optional(map(string), {})
  }))
  default = {}
}
