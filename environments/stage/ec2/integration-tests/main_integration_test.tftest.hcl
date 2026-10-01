# SPDX-License-Identifier: Apache-2.0

# Real-cloud integration test for the stage EC2 composition.
# Run only in a dedicated non-production AWS account/role with the expected
# VPC/subnet fixtures. Terraform test destroys resources created by the run.

variables {
  key_pair_create          = false
  dtrack_name              = "terraform-integration-test"
  dtrack_ec2_instance_type = "t3.micro"
  dtrack_ebs_root_size     = 10
  dtrack_ebs_data_create   = false
  dtrack_eip_create        = false

  tags = {
    Name        = "Terraform Integration Test"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

run "create_component_analysis" {
  command = apply

  assert {
    condition     = module.component_analysis.ec2_instance_id != ""
    error_message = "EC2 instance was not created."
  }
}
