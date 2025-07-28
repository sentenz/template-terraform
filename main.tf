# SPDX-License-Identifier: Apache-2.0

module "component_analysis" {
  source = "./modules/aws-ec2"

  # Module
  name = var.dtrack_name

  # Key Pair
  key_pair_create = var.key_pair_create
  key_path        = var.key_path

  # VPC
  vpc_create = var.vpc_create
  vpc_id     = data.aws_vpc.existing.id

  # EC2 Instance
  ec2_instance_type = var.dtrack_ec2_instance_type
  ec2_subnet_id     = data.aws_subnet.existing_private_az2.id

  # Security Group
  sg_ingress_cidr_blocks      = var.dtrack_sg_ingress_cidr_blocks
  sg_ingress_ipv6_cidr_blocks = var.dtrack_sg_ingress_ipv6_cidr_blocks
  sg_ingress_rules            = var.dtrack_sg_ingress_rules
  sg_egress_rules             = var.dtrack_sg_egress_rules
  # NOTE Comment in for custome ingress rules
  # sg_ingress_with_cidr_blocks = var.dtrack_sg_ingress_with_cidr_blocks

  # EBS Volume
  ebs_data_create      = var.dtrack_ebs_data_create
  ebs_root_volume_size = var.dtrack_ebs_root_volume_size
  ebs_data_volume_size = var.dtrack_ebs_data_volume_size

  # EIP
  eip_create = var.dtrack_eip_create

  tags = var.tags
}
