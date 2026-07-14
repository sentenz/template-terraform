# SPDX-License-Identifier: Apache-2.0

locals {
  key_name            = "${var.name}_key-pair"
  vpc_name            = "${var.name}_vpc"
  security_group_name = "${var.name}_security-group"
  ec2_name            = "${var.name}_ec2-instance"
  eip_name            = "${var.name}_eip"
  ebs_root_name       = "${var.name}_ebs-root"
  ebs_data_name       = "${var.name}_ebs-data"

  security_group_rule_catalog = {
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
    ssh-22-tcp = {
      description = "SSH"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
    }
  }

  security_group_ingress_ipv4_rules = {
    for item in flatten([
      for rule_name in var.security_group_ingress_rules : [
        for index, cidr in var.security_group_ingress_cidr_blocks : {
          key = "${rule_name}-ipv4-${index}"
          value = {
            name                         = rule_name
            cidr_ipv4                    = cidr
            cidr_ipv6                    = null
            description                  = local.security_group_rule_catalog[rule_name].description
            from_port                    = local.security_group_rule_catalog[rule_name].from_port
            ip_protocol                  = local.security_group_rule_catalog[rule_name].ip_protocol
            prefix_list_id               = null
            referenced_security_group_id = null
            tags                         = {}
            to_port                      = local.security_group_rule_catalog[rule_name].to_port
          }
        }
      ]
    ]) : item.key => item.value
  }

  security_group_ingress_ipv6_rules = {
    for item in flatten([
      for rule_name in var.security_group_ingress_rules : [
        for index, cidr in var.security_group_ingress_ipv6_cidr_blocks : {
          key = "${rule_name}-ipv6-${index}"
          value = {
            name                         = rule_name
            cidr_ipv4                    = null
            cidr_ipv6                    = cidr
            description                  = local.security_group_rule_catalog[rule_name].description
            from_port                    = local.security_group_rule_catalog[rule_name].from_port
            ip_protocol                  = local.security_group_rule_catalog[rule_name].ip_protocol
            prefix_list_id               = null
            referenced_security_group_id = null
            tags                         = {}
            to_port                      = local.security_group_rule_catalog[rule_name].to_port
          }
        }
      ]
    ]) : item.key => item.value
  }

  security_group_ingress_custom_rules = {
    for index, rule in var.security_group_ingress_with_cidr_blocks :
    "custom-${index}" => {
      name                         = "custom-${index}"
      cidr_ipv4                    = strcontains(rule.cidr_blocks, ":") ? null : rule.cidr_blocks
      cidr_ipv6                    = strcontains(rule.cidr_blocks, ":") ? rule.cidr_blocks : null
      description                  = rule.description
      from_port                    = rule.from_port
      ip_protocol                  = rule.protocol
      prefix_list_id               = null
      referenced_security_group_id = null
      tags                         = {}
      to_port                      = rule.to_port
    }
  }

  security_group_ingress_rules = merge(
    local.security_group_ingress_ipv4_rules,
    local.security_group_ingress_ipv6_rules,
    local.security_group_ingress_custom_rules,
  )

  security_group_egress_rules = {
    for index, rule_name in var.security_group_egress_rules :
    "${rule_name}-${index}" => {
      name                         = rule_name
      cidr_ipv4                    = "0.0.0.0/0"
      cidr_ipv6                    = null
      description                  = local.security_group_rule_catalog[rule_name].description
      from_port                    = local.security_group_rule_catalog[rule_name].from_port
      ip_protocol                  = local.security_group_rule_catalog[rule_name].ip_protocol
      prefix_list_id               = null
      referenced_security_group_id = null
      tags                         = {}
      to_port                      = local.security_group_rule_catalog[rule_name].to_port
    }
  }
}
