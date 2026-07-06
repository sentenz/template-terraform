# SPDX-License-Identifier: Apache-2.0

module "component_analysis" {
  source = "../../../modules/aws-ec2"

  name = var.dtrack_name

  # Key Pair
  key_pair_create = var.key_pair_create
  key_path        = var.key_path

  # VPC
  vpc_create = var.vpc_create
  vpc_id     = data.aws_vpc.existing.id

  # Security Group
  security_group_ingress_cidr_blocks      = var.dtrack_security_group_ingress_cidr_blocks
  security_group_ingress_ipv6_cidr_blocks = var.dtrack_security_group_ingress_ipv6_cidr_blocks
  security_group_ingress_rules            = var.dtrack_security_group_ingress_rules
  security_group_egress_rules             = var.dtrack_security_group_egress_rules

  # EC2 Instance
  ec2_instance_type = var.dtrack_ec2_instance_type
  ec2_subnet_id     = data.aws_subnet.existing_private_az2.id

  # Elastic Block Store (EBS) Volume
  ebs_data_create      = var.dtrack_ebs_data_create
  ebs_root_size        = var.dtrack_ebs_root_size
  ebs_data_size        = var.dtrack_ebs_data_size
  ebs_data_throughput  = var.dtrack_ebs_data_throughput
  ebs_data_snapshot_id = var.dtrack_ebs_data_snapshot_id

  # Elastic IP
  eip_create = var.dtrack_eip_create

  tags = var.tags
}
