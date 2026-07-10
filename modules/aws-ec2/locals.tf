# SPDX-License-Identifier: Apache-2.0

locals {
  key_name            = "${var.name}_key-pair"
  vpc_name            = "${var.name}_vpc"
  security_group_name = "${var.name}_security-group"
  ec2_name            = "${var.name}_ec2-instance"
  eip_name            = "${var.name}_eip"
  ebs_root_name       = "${var.name}_ebs-root"
  ebs_data_name       = "${var.name}_ebs-data"

  vpc_az_count = max(length(var.vpc_private_subnets), length(var.vpc_public_subnets))
  vpc_azs = var.vpc_create ? slice(
    data.aws_availability_zones.available[0].names,
    0,
    local.vpc_az_count,
  ) : []

  security_group_rule_presets = {
    http-80-tcp = {
      description = "HTTP"
      from_port   = 80
      ip_protocol = "tcp"
      to_port     = 80
    }
    https-443-tcp = {
      description = "HTTPS"
      from_port   = 443
      ip_protocol = "tcp"
      to_port     = 443
    }
    ssh-tcp = {
      description = "SSH"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
    }
  }

  security_group_ingress_ipv4_rules = {
    for item in flatten([
      for rule_name in var.security_group_ingress_rules : [
        for cidr in var.security_group_ingress_cidr_blocks : {
          key = "${rule_name}|ipv4|${cidr}"
          value = merge(
            try(local.security_group_rule_presets[rule_name], {}),
            { cidr_ipv4 = cidr },
          )
        }
      ]
    ]) : item.key => item.value
  }

  security_group_ingress_ipv6_rules = {
    for item in flatten([
      for rule_name in var.security_group_ingress_rules : [
        for cidr in var.security_group_ingress_ipv6_cidr_blocks : {
          key = "${rule_name}|ipv6|${cidr}"
          value = merge(
            try(local.security_group_rule_presets[rule_name], {}),
            { cidr_ipv6 = cidr },
          )
        }
      ]
    ]) : item.key => item.value
  }

  security_group_ingress_explicit_rules = {
    for item in flatten([
      for rule_index, rule in var.security_group_ingress_with_cidr_blocks : [
        for cidr in split(",", rule.cidr_blocks) : {
          key = "explicit-${rule_index}|${trimspace(cidr)}"
          value = {
            cidr_ipv4   = trimspace(cidr)
            description = rule.description
            from_port   = rule.from_port
            ip_protocol = rule.protocol
            to_port     = rule.to_port
          }
        }
      ]
    ]) : item.key => item.value
  }

  security_group_ingress_rules = merge(
    local.security_group_ingress_ipv4_rules,
    local.security_group_ingress_ipv6_rules,
    local.security_group_ingress_explicit_rules,
  )

  security_group_egress_rules = {
    for rule_name in var.security_group_egress_rules :
    "${rule_name}|ipv4|0.0.0.0/0" => merge(
      try(local.security_group_rule_presets[rule_name], {}),
      { cidr_ipv4 = "0.0.0.0/0" },
    )
  }
}
