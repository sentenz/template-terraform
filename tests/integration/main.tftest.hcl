# Test Fixtures
variables {
  instance_type    = "t2.micro"
  root_volume_size = 10
  data_volume_size = 20
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
    dtrack_ec2_instance_type    = var.instance_type
    dtrack_ebs_root_volume_size = var.root_volume_size
    dtrack_ebs_data_volume_size = var.data_volume_size
    tags                        = var.tags
  }

  # Assert
  assert {
    condition     = (module.component_analysis.ec2_instance_id != "")
    error_message = "EC2 instance not created"
  }
}
