# Test Fixtures
variables {
  instance_type = "t2.micro"
  ebs_root_size = 10
  ebs_data_size = 20
  tags = {
    Name        = "Component Analysis"
    Terraform   = "true"
    Environment = "Test"
    Owner       = "DevOps"
  }
}

run "create_module_dtrack" {
  command = apply

  # Arrange
  variables {
    dtrack_ec2_instance_type = var.instance_type
    dtrack_ebs_root_size     = var.ebs_root_size
    dtrack_ebs_data_size     = var.ebs_data_size
    tags                     = var.tags
  }

  # Assert
  assert {
    condition     = (module.component_analysis.ec2_instance_id != "")
    error_message = "EC2 instance not created"
  }
}
