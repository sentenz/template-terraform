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

variable "vpc_create" {
  description = "Whether to create a new VPC for the EKS cluster."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for the cluster when vpc_create is false."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_create || try(length(var.vpc_id) > 0, false)
    error_message = "vpc_id must be provided when vpc_create is false."
  }
}

variable "subnet_ids" {
  description = "Subnets for EKS control plane and default node groups, usually private, when vpc_create is false."
  type        = list(string)
  default     = null

  validation {
    condition     = var.vpc_create || try(length(var.subnet_ids) > 0, false)
    error_message = "subnet_ids must contain at least one subnet ID when vpc_create is false."
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC created by this module."
  type        = string
  default     = "10.42.0.0/16"
}

variable "vpc_private_subnets" {
  description = "List of private subnet CIDR blocks for a module-created VPC."
  type        = list(string)
  default     = ["10.42.0.0/19", "10.42.32.0/19", "10.42.64.0/19"]
}

variable "vpc_public_subnets" {
  description = "List of public subnet CIDR blocks for a module-created VPC."
  type        = list(string)
  default     = ["10.42.96.0/20", "10.42.112.0/20", "10.42.128.0/20"]
}

variable "vpc_enable_nat_gateway" {
  description = "Whether to enable NAT gateways for a module-created VPC."
  type        = bool
  default     = true
}

variable "vpc_single_nat_gateway" {
  description = "Whether to use a single NAT gateway for a module-created VPC."
  type        = bool
  default     = false
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
  description = "The virtualization standard, e.g., Hardware Machine Virtual (HVM) used by Amazon EC2 instances."
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

variable "node_subnet_ids" {
  description = "Override subnets for node groups. Defaults to subnet_ids or the private subnets created by this module."
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

variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "create_cluster_kms_key" {
  description = "Create a KMS key for cluster secrets encryption."
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "Principals with admin access to the created KMS key."
  type        = list(string)
  default     = []
}

variable "default_mng_instance_types" {
  description = "Instance types for the default EKS managed node group."
  type        = list(string)
  default     = ["m6i.large"]
}

variable "default_mng_min_size" {
  description = "Minimum size for the default EKS managed node group."
  type        = number
  default     = 2
}

variable "default_mng_desired_size" {
  description = "Desired size for the default EKS managed node group."
  type        = number
  default     = 3
}

variable "default_mng_max_size" {
  description = "Maximum size for the default EKS managed node group."
  type        = number
  default     = 6
}

variable "default_mng_capacity_type" {
  description = "Capacity type for the default EKS managed node group. Valid values are ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.default_mng_capacity_type)
    error_message = "default_mng_capacity_type must be either ON_DEMAND or SPOT."
  }
}

variable "extra_managed_node_groups" {
  description = "Additional managed node groups to merge with the default node group."
  type = map(object({
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
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
  description = "Extra or override cluster add-ons map to merge with defaults."
  type = map(object({
    most_recent              = optional(bool, true)
    resolve_conflicts        = optional(string)
    configuration_values     = optional(string)
    preserve                 = optional(bool)
    service_account_role_arn = optional(string)
  }))
  default = {}
}

variable "pod_identity_associations" {
  description = <<-EOT
    Map of Pod Identity associations. Each entry creates an IAM role with supplied policies and maps it to a Kubernetes service account via AWS Pod Identity.
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
