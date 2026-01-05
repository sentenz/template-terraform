# SPDX-License-Identifier: Apache-2.0

module "component_analysis" {
  source = "../../../"

  # Key Pair
  key_pair_create = var.key_pair_create
  key_path        = var.key_path

  # EC2 Instance
  dtrack_ec2_instance_type = var.dtrack_ec2_instance_type

  # Elastic Block Store (EBS) Volume
  dtrack_ebs_root_size        = var.dtrack_ebs_root_size
  dtrack_ebs_data_size        = var.dtrack_ebs_data_size
  dtrack_ebs_data_throughput  = var.dtrack_ebs_data_throughput
  dtrack_ebs_data_snapshot_id = var.dtrack_ebs_data_snapshot_id

  tags = var.tags
}
