# SPDX-License-Identifier: Apache-2.0

data "aws_ami" "machine" {
  most_recent = var.ami_most_recent
  owners      = var.ami_owners

  filter {
    name   = var.ami_image_name
    values = var.ami_image_patterns
  }

  filter {
    name   = var.ami_virtualization_name
    values = var.ami_virtualization_types
  }

  filter {
    name   = var.ami_device_name
    values = var.ami_device_types
  }
}

data "aws_availability_zones" "available" {
  state = var.azs_state
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name   = local.key_name
  public_key = file(var.key_path)

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

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
  version = "5.2.0"

  name                     = local.sg_name
  description              = var.sg_description
  ingress_cidr_blocks      = var.sg_ingress_cidr_blocks
  ingress_ipv6_cidr_blocks = var.sg_ingress_ipv6_cidr_blocks
  ingress_rules            = var.sg_ingress_rules
  ingress_with_cidr_blocks = var.sg_ingress_with_cidr_blocks
  egress_rules             = var.sg_egress_rules
  vpc_id                   = module.vpc.vpc_id

  tags = var.tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  # EC2 Instance
  name                   = local.ec2_name
  instance_type          = var.ec2_instance_type
  ami                    = data.aws_ami.machine.id
  key_name               = module.key_pair.key_pair_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.security_group.security_group_id]

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
  # XXX(sentenz) Use AWS Systems Manager (SSM) for secure, internal access without requiring a public IP and SSH access with the need for a key pair
  create_eip = var.eip_create
  eip_tags = {
    Name = local.eip_name
  }

  tags = var.tags
}

resource "aws_ebs_volume" "ebs_data_volume" {
  count = var.ebs_data_create ? 1 : 0

  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.ebs_data_volume_size
  type              = var.ebs_data_volume_type
  encrypted         = var.ebs_data_encrypted
  throughput        = var.ebs_data_throughput

  tags = {
    Name = local.ebs_data_name
  }
}

resource "aws_volume_attachment" "ebs_data_attachment" {
  count = var.ebs_data_create ? 1 : 0

  device_name = var.ebs_data_device_name
  volume_id   = aws_ebs_volume.ebs_data_volume[0].id
  instance_id = module.ec2_instance.id
}
