# SPDX-License-Identifier: Apache-2.0

module "dependency_track" {
  source = "./modules/aws-ec2"

  # AWS configuration
  name     = var.dtrack_name
  key_path = var.key_path

  # EC2 instance configuration
  ec2_instance_type = var.dtrack_ec2_instance_type

  # Security group configuration
  sg_ingress_cidr_blocks      = var.dtrack_sg_ingress_cidr_blocks
  sg_ingress_ipv6_cidr_blocks = var.dtrack_sg_ingress_ipv6_cidr_blocks
  sg_ingress_rules            = var.dtrack_sg_ingress_rules
  sg_egress_rules             = var.dtrack_sg_egress_rules
  sg_ingress_with_cidr_blocks = var.dtrack_sg_ingress_with_cidr_blocks

  # EBS volume configuration
  ebs_data_create      = var.dtrack_ebs_data_create
  ebs_root_volume_size = var.dtrack_ebs_root_volume_size
  ebs_data_volume_size = var.dtrack_ebs_data_volume_size

  # EIP configuration
  eip_create = var.dtrack_eip_create

  tags = var.tags
}
