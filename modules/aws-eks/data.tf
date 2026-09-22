# SPDX-License-Identifier: Apache-2.0

data "aws_availability_zones" "available" {
  state = var.azs_state
}
