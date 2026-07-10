# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "The EKS cluster name."
  type        = string
  default     = "aws-eks"

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
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
    condition     = var.vpc_create || try(can(regex("^vpc-[0-9a-f]+$", var.vpc_id)), false)
    error_message = "vpc_id must be a valid VPC ID when vpc_create is false."
  }
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane and default node groups, usually private, when vpc_create is false."
  type        = list(string)
  default     = null

  validation {
    condition = var.vpc_create || try(
      length(var.subnet_ids) >= 2 && alltrue([
        for subnet_id in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ]),
      false,
    )
    error_message = "subnet_ids must contain at least two valid subnet IDs when vpc_create is false."
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC created by this module."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_private_subnets" {
  description = "List of private subnet CIDR blocks for a module-created VPC."
  type        = list(string)
  default     = ["10.42.0.0/19", "10.42.32.0/19", "10.42.64.0/19"]

  validation {
    condition = !var.vpc_create || (
      length(var.vpc_private_subnets) >= 2 && alltrue([
        for cidr in var.vpc_private_subnets : can(cidrnetmask(cidr))
      ])
    )
    error_message = "vpc_private_subnets must contain at least two valid CIDR blocks when vpc_create is true."
  }
}

variable "vpc_public_subnets" {
  description = "List of public subnet CIDR blocks for a module-created VPC."
  type        = list(string)
  default     = ["10.42.96.0/20", "10.42.112.0/20", "10.42.128.0/20"]

  validation {
    condition = alltrue([
      for cidr in var.vpc_public_subnets : can(cidrnetmask(cidr))
    ])
    error_message = "vpc_public_subnets must contain only valid CIDR blocks."
  }
}

variable "vpc_enable_nat_gateway" {
  description = "Whether to enable NAT gateways for a module-created VPC."
  type        = bool
  default     = true

  validation {
    condition     = !var.vpc_create || !var.vpc_enable_nat_gateway || length(var.vpc_public_subnets) > 0
    error_message = "vpc_public_subnets must not be empty when NAT gateways are enabled."
  }
}

variable "vpc_single_nat_gateway" {
  description = "Whether to use a single NAT gateway for a module-created VPC."
  type        = bool
  default     = false
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

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "kubernetes_version must use the major.minor form, for example 1.33."
  }
}

variable "node_subnet_ids" {
  description = "Override subnets for node groups. Defaults to subnet_ids or the private subnets created by this module."
  type        = list(string)
  default     = null

  validation {
    condition = var.node_subnet_ids == null || (
      length(var.node_subnet_ids) > 0 && alltrue([
        for subnet_id in var.node_subnet_ids : can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "node_subnet_ids must be null or contain valid subnet IDs."
  }
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

  validation {
    condition     = var.endpoint_private_access || var.endpoint_public_access
    error_message = "At least one EKS endpoint access mode must be enabled."
  }
}

variable "endpoint_public_access_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public EKS endpoint. Required when endpoint_public_access is true; unrestricted access is rejected."
  type        = list(string)
  default     = null

  validation {
    condition = !var.endpoint_public_access || try(
      length(var.endpoint_public_access_cidrs) > 0 && alltrue([
        for cidr in var.endpoint_public_access_cidrs :
        can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
      ]),
      false,
    )
    error_message = "endpoint_public_access_cidrs must contain valid, restricted IPv4 CIDRs when public endpoint access is enabled."
  }
}

variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = length(var.enabled_log_types) == length(distinct(var.enabled_log_types)) && alltrue([
      for log_type in var.enabled_log_types : contains(
        ["api", "audit", "authenticator", "controllerManager", "scheduler"],
        log_type,
      )
    ])
    error_message = "enabled_log_types must contain unique, supported EKS control plane log types."
  }
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

  validation {
    condition = alltrue([
      for principal_arn in var.kms_key_administrators : can(regex("^arn:[^:]+:iam::[0-9]{12}:(role|user)/.+$", principal_arn))
    ])
    error_message = "kms_key_administrators must contain IAM role or user ARNs."
  }
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Whether to grant the Terraform caller cluster-admin access through an EKS access entry. Prefer explicit access entries for long-lived environments."
  type        = bool
  default     = false
}

variable "default_mng_instance_types" {
  description = "Instance types for the default EKS managed node group."
  type        = list(string)
  default     = ["m6i.large"]

  validation {
    condition     = length(var.default_mng_instance_types) > 0
    error_message = "default_mng_instance_types must contain at least one instance type."
  }
}

variable "default_mng_min_size" {
  description = "Minimum size for the default EKS managed node group."
  type        = number
  default     = 2

  validation {
    condition     = var.default_mng_min_size >= 0
    error_message = "default_mng_min_size must be zero or greater."
  }
}

variable "default_mng_desired_size" {
  description = "Desired size for the default EKS managed node group."
  type        = number
  default     = 3

  validation {
    condition = (
      var.default_mng_desired_size >= var.default_mng_min_size &&
      var.default_mng_desired_size <= var.default_mng_max_size
    )
    error_message = "default_mng_desired_size must be between default_mng_min_size and default_mng_max_size."
  }
}

variable "default_mng_max_size" {
  description = "Maximum size for the default EKS managed node group."
  type        = number
  default     = 6

  validation {
    condition     = var.default_mng_max_size >= var.default_mng_min_size
    error_message = "default_mng_max_size must be greater than or equal to default_mng_min_size."
  }
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

  validation {
    condition = alltrue([
      for group in values(var.extra_managed_node_groups) :
      length(group.instance_types) > 0 &&
      group.min_size >= 0 &&
      group.desired_size >= group.min_size &&
      group.desired_size <= group.max_size &&
      group.disk_size > 0 &&
      contains(["ON_DEMAND", "SPOT"], group.capacity_type) &&
      alltrue([
        for taint in group.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
      ])
    ])
    error_message = "Each extra managed node group must have valid scaling bounds, instance types, disk size, capacity type, and taint effects."
  }
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

  validation {
    condition = alltrue([
      for profile in values(var.fargate_profiles) :
      length(trimspace(profile.name)) > 0 && length(profile.selectors) > 0
    ])
    error_message = "Each Fargate profile must have a non-empty name and at least one selector."
  }
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
  description = "Map of Pod Identity associations that create IAM roles and associate them with Kubernetes service accounts."
  type = map(object({
    namespace       = string
    service_account = string
    role_name       = string
    policy_arns     = optional(list(string), [])
    policies_json   = optional(list(string), [])
    tags            = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for association in values(var.pod_identity_associations) :
      length(trimspace(association.namespace)) > 0 &&
      length(trimspace(association.service_account)) > 0 &&
      length(trimspace(association.role_name)) > 0 &&
      alltrue([
        for policy_arn in association.policy_arns : can(regex("^arn:[^:]+:iam::[0-9]{12}:policy/.+$", policy_arn))
      ])
    ])
    error_message = "Pod Identity associations require namespace, service_account, role_name, and valid IAM policy ARNs."
  }
}
