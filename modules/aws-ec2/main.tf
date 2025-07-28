# SPDX-License-Identifier: Apache-2.0

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  count = var.key_pair_create ? 1 : 0

  key_name   = local.key_name
  public_key = file(var.key_path)

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  count = var.vpc_create ? 1 : 0

  name               = local.vpc_name
  cidr               = var.vpc_cidr
  private_subnets    = var.vpc_private_subnets
  public_subnets     = var.vpc_public_subnets
  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway
  azs                = data.aws_availability_zones.available.names

  tags = var.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name                     = local.sg_name
  description              = var.sg_description
  ingress_cidr_blocks      = var.sg_ingress_cidr_blocks
  ingress_ipv6_cidr_blocks = var.sg_ingress_ipv6_cidr_blocks
  ingress_rules            = var.sg_ingress_rules
  ingress_with_cidr_blocks = var.sg_ingress_with_cidr_blocks
  egress_rules             = var.sg_egress_rules
  vpc_id                   = coalesce(try(module.vpc[0].vpc_id, null), var.vpc_id)

  tags = var.tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"

  # EC2 Instance
  name                   = local.ec2_name
  instance_type          = var.ec2_instance_type
  ami                    = data.aws_ami.machine.id
  key_name               = try(module.key_pair[0].key_pair_name, null)
  subnet_id              = coalesce(try(module.vpc[0].public_subnets[0], null), var.ec2_subnet_id)
  vpc_security_group_ids = [module.security_group.security_group_id]
  ignore_ami_changes     = var.ec2_ignore_ami_changes

  # Elastic Block Store (EBS) Volume
  enable_volume_tags = var.ebs_root_enable_tags
  root_block_device = [{
    encrypted   = var.ebs_root_encrypted
    volume_type = var.ebs_root_volume_type
    throughput  = var.ebs_root_throughput
    volume_size = var.ebs_root_volume_size
    tags = {
      Name = local.ebs_root_name
    }
  }]

  # Elastic IP (EIP) and Association
  #
  # XXX Use AWS Systems Manager (SSM) for secure, internal access without requiring a public IP and SSH access with the need for a key pair
  # See https://github.com/terraform-aws-modules/terraform-aws-ec2-instance/pull/391
  create_eip = var.eip_create
  eip_tags = {
    Name = local.eip_name
  }

  tags = var.tags
}

resource "aws_ebs_volume" "this" {
  count = var.ebs_data_create ? 1 : 0

  availability_zone = module.ec2_instance.availability_zone
  size              = var.ebs_data_volume_size
  type              = var.ebs_data_volume_type
  encrypted         = var.ebs_data_encrypted
  throughput        = var.ebs_data_throughput

  tags = {
    Name = local.ebs_data_name
  }
}

resource "aws_volume_attachment" "this" {
  count = var.ebs_data_create ? 1 : 0

  device_name = var.ebs_data_device_name
  volume_id   = aws_ebs_volume.this[0].id
  instance_id = module.ec2_instance.id
}
