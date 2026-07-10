# SPDX-License-Identifier: Apache-2.0

data "aws_availability_zones" "available" {
  count = var.vpc_create ? 1 : 0

  state = var.azs_state
}
