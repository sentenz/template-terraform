# SPDX-License-Identifier: Apache-2.0

locals {
  key_name            = "${var.name}_key-pair"
  vpc_name            = "${var.name}_vpc"
  security_group_name = "${var.name}_security-group"
  ec2_name            = "${var.name}_ec2-instance"
  eip_name            = "${var.name}_eip"
  ebs_root_name       = "${var.name}_ebs-root"
  ebs_data_name       = "${var.name}_ebs-data"
}
