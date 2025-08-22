# --- Test Fixtures -------------------------------------------------------------------------------

# Stub out AWS data sources used by the module under test
provider "aws" {
  region                      = "us-east-1"
  profile                     = "stage"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  # # Applies to all data "aws_vpc" instances
  # mock_data "aws_vpc" {
  #   defaults = {
  #     id         = "vpc-0123456789abcdef0"
  #     cidr_block = "10.0.0.0/16"
  #   }
  # }

  # # Applies to all data "aws_subnet" instances (any names)
  # mock_data "aws_subnet" {
  #   defaults = {
  #     id                = "subnet-0123456789abcdef0"
  #     vpc_id            = "vpc-0123456789abcdef0"
  #     availability_zone = "us-east-1a"
  #     cidr_block        = "10.0.0.0/24"
  #   }
  # }

  # # If the module reads an AMI via data.aws_ami.machine
  # mock_data "aws_ami" {
  #   defaults = {
  #     id = "ami-0123456789abcdef0"
  #   }
  # }

  # # If availability zones are read (e.g., for VPC/azs)
  # mock_data "aws_availability_zones" {
  #   defaults = {
  #     names = ["us-east-1a", "us-east-1b", "us-east-1c"]
  #   }
  # }
}
# --- Test Fixtures -------------------------------------------------------------------------------

variables {
  # Required by module but not under test here (placeholder)
  dtrack_name       = "component-analysis"
  key_pair_create   = false
  vpc_create        = false
  vpc_id            = "vpc-0123456789abcdef0"
  dtrack_eip_create = false

  # Place instance in a private subnet (placeholder)
  dtrack_ec2_instance_type = "t3.small"
  ec2_subnet_id            = "subnet-0123456789abcdef0"

  # Root volume (happy path values so plan proceeds)
  dtrack_ebs_root_size       = 10
  dtrack_ebs_root_type       = "gp3"
  dtrack_ebs_root_throughput = 125

  # Data volume enabled so ebs_volumes path is exercised
  dtrack_ebs_data_create      = true
  dtrack_ebs_data_size        = 20
  dtrack_ebs_data_type        = "gp3"
  dtrack_ebs_data_throughput  = 125
  dtrack_ebs_data_device_name = "/dev/sdf"

  # Hardened SG defaults (no public ingress)
  dtrack_security_group_ingress_cidr_blocks      = []
  dtrack_security_group_ingress_ipv6_cidr_blocks = []
  dtrack_security_group_ingress_rules            = ["https-443-tcp"]
  dtrack_security_group_egress_rules             = ["https-443-tcp"]
  dtrack_security_group_ingress_with_cidr_blocks = []

  # Tags required by module validations
  tags = {
    Name        = "Component Analysis"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

# --- Tests ---------------------------------------------------------------------------------------

run "invalid_instance_type" {
  command = plan

  variables {
    dtrack_ec2_instance_type = "m5.large" # expected to violate module validation
    dtrack_ebs_root_size     = var.dtrack_ebs_root_size
    dtrack_ebs_data_size     = var.dtrack_ebs_data_size
    tags                     = var.tags
  }

  expect_failures = [var.dtrack_ec2_instance_type]
}

run "invalid_ebs_root_size" {
  command = plan

  variables {
    dtrack_ec2_instance_type = var.dtrack_ec2_instance_type
    dtrack_ebs_root_size     = -1 # invalid
    dtrack_ebs_data_size     = var.dtrack_ebs_data_size
    tags                     = var.tags
  }

  expect_failures = [var.dtrack_ebs_root_size]
}

run "invalid_ebs_data_size" {
  command = plan

  variables {
    dtrack_ec2_instance_type = var.dtrack_ec2_instance_type
    dtrack_ebs_root_size     = var.dtrack_ebs_root_size
    dtrack_ebs_data_size     = -1 # invalid
    tags                     = var.tags
  }

  expect_failures = [var.dtrack_ebs_data_size]
}

run "invalid_tags" {
  command = plan

  variables {
    dtrack_ec2_instance_type = var.dtrack_ec2_instance_type
    dtrack_ebs_root_size     = var.dtrack_ebs_root_size
    dtrack_ebs_data_size     = var.dtrack_ebs_data_size
    tags                     = {} # missing required tags
  }

  expect_failures = [var.tags]
}
