# SPDX-License-Identifier: Apache-2.0

module "root" {
  source = "../../"

  dtrack_ec2_instance_type    = var.dtrack_ec2_instance_type
  dtrack_ebs_root_volume_size = var.dtrack_ebs_root_volume_size
  dtrack_ebs_data_volume_size = var.dtrack_ebs_data_volume_size

  tags = var.tags
}
