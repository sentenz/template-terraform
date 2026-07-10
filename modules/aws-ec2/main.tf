# SPDX-License-Identifier: Apache-2.0

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "3.0.0"

  count = var.key_pair_create ? 1 : 0

  key_name   = local.key_name
  public_key = file(var.key_path)

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  count = var.vpc_create ? 1 : 0

  name               = local.vpc_name
  cidr               = var.vpc_cidr
  private_subnets    = var.vpc_private_subnets
  public_subnets     = var.vpc_public_subnets
  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway
  azs                = local.vpc_azs

  tags = var.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name          = local.security_group_name
  description   = var.security_group_description
  ingress_rules = local.security_group_ingress_rules
  egress_rules  = local.security_group_egress_rules
  vpc_id        = coalesce(try(module.vpc[0].vpc_id, null), var.vpc_id)

  tags = merge(var.tags, { Name = local.security_group_name })
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  name                   = local.ec2_name
  instance_type          = var.ec2_instance_type
  ami                    = data.aws_ami.machine.id
  key_name               = try(module.key_pair[0].key_pair_name, null)
  subnet_id              = coalesce(try(module.vpc[0].public_subnets[0], null), var.ec2_subnet_id)
  vpc_security_group_ids = [module.security_group.id]
  ignore_ami_changes     = var.ec2_ignore_ami_changes

  create_security_group = false

  ebs_optimized      = var.ebs_optimized
  enable_volume_tags = var.ebs_enable_volume_tags

  root_block_device = {
    encrypted  = var.ebs_root_encrypted
    size       = var.ebs_root_size
    type       = var.ebs_root_type
    iops       = var.ebs_root_iops
    throughput = var.ebs_root_throughput
    tags = {
      Name = local.ebs_root_name
    }
  }

  ebs_volumes = var.ebs_data_create ? {
    data = {
      device_name = var.ebs_data_device_name
      encrypted   = var.ebs_data_encrypted
      size        = var.ebs_data_size
      type        = var.ebs_data_type
      iops        = var.ebs_data_iops
      throughput  = var.ebs_data_throughput
      snapshot_id = var.ebs_data_snapshot_id
      tags = {
        Name = local.ebs_data_name
      }
    }
  } : null

  create_eip = var.eip_create
  eip_tags = {
    Name = local.eip_name
  }

  tags = var.tags
}
