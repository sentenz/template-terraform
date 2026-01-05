# SPDX-License-Identifier: Apache-2.0

data "aws_vpc" "existing" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["VPC for Hosting"]
  }
}

data "aws_subnet" "existing_public_az1" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["Public-1a"]
  }
}

data "aws_subnet" "existing_private_az1" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["Private-1a"]
  }
}

data "aws_subnet" "existing_public_az2" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["Public-1b"]
  }
}

data "aws_subnet" "existing_private_az2" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["Private-1b"]
  }
}
